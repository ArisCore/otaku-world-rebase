import 'dart:convert';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:otaku_world/constants/filter_constants.dart';
import 'package:otaku_world/constants/string_constants.dart';
import 'package:otaku_world/core/model/anime_filter.dart';
import 'package:otaku_world/core/model/filter_model.dart';
import 'package:otaku_world/core/model/manga_filter.dart';
import 'package:otaku_world/core/types/enums.dart';
import 'package:otaku_world/graphql/__generated/graphql/fragments.graphql.dart';
import 'package:otaku_world/graphql/__generated/graphql/list/media_list.graphql.dart';
import 'package:otaku_world/graphql/__generated/graphql/schema.graphql.dart';
import 'package:otaku_world/utils/formatting_utils.dart';

part 'media_list_event.dart';
part 'media_list_state.dart';

class AnimeListBloc extends MediaListBloc {
  AnimeListBloc() : super(type: Enum$MediaType.ANIME);
}

class MangaListBloc extends MediaListBloc {
  MangaListBloc() : super(type: Enum$MediaType.MANGA);
}

class MediaListBloc extends Bloc<MediaListEvent, MediaListState> {
  MediaListBloc({required this.type}) : super(MediaListInitial()) {
    filter = type == Enum$MediaType.ANIME
        ? const AnimeFilter(sort: [Enum$MediaSort.UPDATED_AT_DESC])
        : const MangaFilter(sort: [Enum$MediaSort.UPDATED_AT_DESC]);

    on<LoadMediaList>(_onLoadMediaList);
    on<ApplyFilter>(_onApplyFilter);
    on<UpdateListEntry>(_onUpdateListEntry);
    on<RemoveListEntry>(_onRemoveListEntry);
    on<ClearSearch>(_onClearSearch);
    on<RemoveFilters>(_onRemoveFilters);
  }

  final Enum$MediaType type;
  int? userId;

  /// Master copy of all collections, updated on CRUD operations
  late Query$MediaList$MediaListCollection _masterCollection;
  Fragment$MediaListOptions? options;

  List<String> _selectedLists = [];
  late FilterModel filter;
  bool searchApplied = false;
  bool filterApplied = false;

  List<String> get selectedLists => _selectedLists;

  /// Helper to determine the exact collection name for an entry,
  /// respecting "split completed list by format" setting.
  String _collectionNameForEntry(Fragment$MediaListEntry entry) {
    final base = FormattingUtils.getMediaListStatusString(
      entry.status,
      isAnime: type == Enum$MediaType.ANIME,
    );
    final isCompleted = entry.status == Enum$MediaListStatus.COMPLETED;
    final splitCompleted = entry.media?.type == Enum$MediaType.ANIME
        ? (options?.animeList?.splitCompletedSectionByFormat ?? false)
        : (options?.mangaList?.splitCompletedSectionByFormat ?? false);

    if (isCompleted && splitCompleted) {
      final fmt = FormattingUtils.getMediaFormatString(
        entry.media?.format,
        forList: true,
      );
      return '$base $fmt';
    }
    return base;
  }

  Future<void> _onLoadMediaList(
    LoadMediaList event,
    Emitter<MediaListState> emit,
  ) async {
    if (event.loadForSettings && state is! MediaListLoaded) return;

    emit(MediaListLoading());
    filter = filter.reset();
    _selectedLists = [];
    filterApplied = false;
    searchApplied = false;

    final response = await event.client.query$MediaList(
      Options$Query$MediaList(
        fetchPolicy: FetchPolicy.networkOnly,
        cacheRereadPolicy: CacheRereadPolicy.ignoreAll,
        variables: Variables$Query$MediaList(
          type: type,
          userId: userId,
        ),
      ),
    );

    if (response.hasException ||
        response.parsedData?.MediaListCollection == null) {
      final linkEx = response.exception?.linkException;
      if (linkEx != null && linkEx is ServerException) {
        emit(const MediaListError(
          type: ErrorType.noInternet,
          message: StringConstants.noInternetError,
        ));
      } else {
        emit(const MediaListError(
          type: ErrorType.unknown,
          message: StringConstants.somethingWentWrongError,
        ));
      }
      return;
    }

    final data = response.parsedData!.MediaListCollection!;
    _masterCollection = data;
    options = data.user?.mediaListOptions;

    emit(MediaListLoaded(listCollection: _masterCollection));
  }

  /// Applies current filter/search settings to a given collection
  Query$MediaList$MediaListCollection _applyFilters(
    Query$MediaList$MediaListCollection input,
  ) {
    final lists = input.lists
            ?.map(
              (collection) {
                if (collection == null) return null;

                // Filter entries
                final filteredEntries = collection.entries?.where(
                      (entry) {
                        bool matches = true;
                        final media = entry?.media;

                        if (filter.search != null &&
                            filter.search!.isNotEmpty) {
                          matches &= media?.title?.userPreferred
                                  ?.toLowerCase()
                                  .contains(filter.search!.toLowerCase()) ??
                              false;
                          searchApplied = true;
                        } else {
                          searchApplied = false;
                        }

                        if (_selectedLists.isNotEmpty) {
                          matches &= _selectedLists.contains(collection.name);
                        }

                        if (type == Enum$MediaType.ANIME) {
                          final animeFilter = filter as AnimeFilter;
                          if (animeFilter.startDateGreater != null &&
                              animeFilter.startDateLesser != null &&
                              media?.startDate?.year != null) {
                            matches &= media!.startDate!.year! >=
                                    int.parse(animeFilter.startDateGreater!) &&
                                media.startDate!.year! <=
                                    int.parse(animeFilter.startDateLesser!);
                          }

                          if (animeFilter.genres != null &&
                              animeFilter.genres!.isNotEmpty) {
                            matches &= media?.genres?.any(
                                    (g) => animeFilter.genres!.contains(g)) ??
                                false;
                          }
                          if (animeFilter.formatIn != null &&
                              animeFilter.formatIn!.isNotEmpty) {
                            matches &=
                                animeFilter.formatIn!.contains(media?.format);
                          }
                          if (animeFilter.statusIn != null &&
                              animeFilter.statusIn!.isNotEmpty) {
                            matches &=
                                animeFilter.statusIn!.contains(media?.status);
                          }
                          if (animeFilter.countryOfOrigin != null) {
                            matches &= media?.countryOfOrigin ==
                                animeFilter.countryOfOrigin;
                          }
                        } else {
                          final mangaFilter = filter as MangaFilter;
                          if (mangaFilter.startDateGreater != null &&
                              mangaFilter.startDateLesser != null &&
                              media?.startDate?.year != null) {
                            matches &= media!.startDate!.year! >=
                                    int.parse(mangaFilter.startDateGreater!) &&
                                media.startDate!.year! <=
                                    int.parse(mangaFilter.startDateLesser!);
                          }

                          if (mangaFilter.genres != null &&
                              mangaFilter.genres!.isNotEmpty) {
                            matches &= media?.genres?.any(
                                    (g) => mangaFilter.genres!.contains(g)) ??
                                false;
                          }
                          if (mangaFilter.formatIn != null &&
                              mangaFilter.formatIn!.isNotEmpty) {
                            matches &=
                                mangaFilter.formatIn!.contains(media?.format);
                          }
                          if (mangaFilter.statusIn != null &&
                              mangaFilter.statusIn!.isNotEmpty) {
                            matches &=
                                mangaFilter.statusIn!.contains(media?.status);
                          }
                          if (mangaFilter.countryOfOrigin != null) {
                            matches &= media?.countryOfOrigin ==
                                mangaFilter.countryOfOrigin;
                          }
                        }

                        return matches;
                      },
                    ).toList() ??
                    [];

                final sorted = _sortEntries(filteredEntries);
                return collection.copyWith(entries: sorted);
              },
            )
            .where((c) => (c?.entries ?? []).isNotEmpty)
            .toList() ??
        [];

    return input.copyWith(lists: lists);
  }

  /// Sort logic extracted to reuse across filter and initial load
  List<Fragment$MediaListEntry?> _sortEntries(
    List<Fragment$MediaListEntry?> list,
  ) {
    if (list.isEmpty) return list;

    final sortOption = type == Enum$MediaType.ANIME
        ? (filter as AnimeFilter).listSort
        : (filter as MangaFilter).listSort;

    list.sort((a, b) {
      int primaryCompare;
      switch (sortOption) {
        case Enum$MediaListSort.MEDIA_TITLE_ROMAJI:
          primaryCompare = (a?.media?.title?.userPreferred ?? '')
              .compareTo(b?.media?.title?.userPreferred ?? '');
          break;
        case Enum$MediaListSort.SCORE_DESC:
          primaryCompare = (b?.score ?? 0).compareTo(a?.score ?? 0);
          break;
        case Enum$MediaListSort.PROGRESS_DESC:
          primaryCompare = (b?.progress ?? 0).compareTo(a?.progress ?? 0);
          break;
        case Enum$MediaListSort.UPDATED_TIME_DESC:
          primaryCompare = (b?.updatedAt ?? 0).compareTo(a?.updatedAt ?? 0);
          break;
        case Enum$MediaListSort.ADDED_TIME_DESC:
          primaryCompare = (b?.createdAt ?? 0).compareTo(a?.createdAt ?? 0);
          break;
        case Enum$MediaListSort.STARTED_ON_DESC:
          final aTime = DateTime(
            a?.startedAt?.year ?? FilterConstants.mediaYearMinimum.toInt(),
            a?.startedAt?.month ?? 1,
            a?.startedAt?.day ?? 1,
          );
          final bTime = DateTime(
            b?.startedAt?.year ?? FilterConstants.mediaYearMinimum.toInt(),
            b?.startedAt?.month ?? 1,
            b?.startedAt?.day ?? 1,
          );
          primaryCompare = bTime.compareTo(aTime);
          break;
        case Enum$MediaListSort.FINISHED_ON_DESC:
          final aFinish = DateTime(
            a?.completedAt?.year ?? FilterConstants.mediaYearMinimum.toInt(),
            a?.completedAt?.month ?? 1,
            a?.completedAt?.day ?? 1,
          );
          final bFinish = DateTime(
            b?.completedAt?.year ?? FilterConstants.mediaYearMinimum.toInt(),
            b?.completedAt?.month ?? 1,
            b?.completedAt?.day ?? 1,
          );
          primaryCompare = bFinish.compareTo(aFinish);
          break;
        case Enum$MediaListSort.ADDED_TIME:
          final aRelease = DateTime(
            a?.media?.startDate?.year ??
                FilterConstants.mediaYearMinimum.toInt(),
            a?.media?.startDate?.month ?? 1,
            a?.media?.startDate?.day ?? 1,
          );
          final bRelease = DateTime(
            b?.media?.startDate?.year ??
                FilterConstants.mediaYearMinimum.toInt(),
            b?.media?.startDate?.month ?? 1,
            b?.media?.startDate?.day ?? 1,
          );
          primaryCompare = bRelease.compareTo(aRelease);
          break;
        case Enum$MediaListSort.MEDIA_ID_DESC:
          primaryCompare = (b?.media?.averageScore ?? 0)
              .compareTo(a?.media?.averageScore ?? 0);
          break;
        case Enum$MediaListSort.MEDIA_POPULARITY_DESC:
        default:
          primaryCompare =
              (b?.media?.popularity ?? 0).compareTo(a?.media?.popularity ?? 0);
      }
      if (primaryCompare == 0) {
        return (a?.media?.title?.userPreferred ?? '')
            .compareTo(b?.media?.title?.userPreferred ?? '');
      }
      return primaryCompare;
    });

    return list;
  }

  void _onApplyFilter(ApplyFilter event, Emitter<MediaListState> emit) {
    if (type == Enum$MediaType.ANIME) {
      filter = ((event.mediaFilter ?? filter) as AnimeFilter)
          .copyWith(search: event.search);
    } else {
      filter = ((event.mediaFilter ?? filter) as MangaFilter)
          .copyWith(search: event.search);
    }

    if (event.lists != null && event.lists!.isNotEmpty) {
      _selectedLists = event.lists!;
    }

    filterApplied =
        (event.mediaFilter != null) || (event.lists?.isNotEmpty ?? false);

    final filtered = _applyFilters(_masterCollection);
    emit(MediaListLoaded(listCollection: filtered));
  }

  void _onUpdateListEntry(UpdateListEntry event, Emitter<MediaListState> emit) {
    if (state is! MediaListLoaded) return;

    // Determine primary bucket based on status/split logic
    final statusBucket = _collectionNameForEntry(event.entry);
    // Include any custom lists the entry belongs to
    Set<String> targetBuckets = {statusBucket};

    if (event.entry.customLists != null && event.entry.customLists!.isNotEmpty) {
      final decoded = jsonDecode(event.entry.customLists!);
      if (decoded != null && decoded is Map<String, dynamic>) {
        final customBuckets = decoded.entries
            .where((e) => e.value)
            .map((e) => e.key);
        targetBuckets.addAll(customBuckets);
      }
    }

    bool foundAny = false;
    // Update master collection: place entry in all target buckets, remove from others
    final updatedLists = _masterCollection.lists?.map((collection) {
          if (collection == null) return null;
          final entries =
              List<Fragment$MediaListEntry?>.of(collection.entries ?? []);

          if (targetBuckets.contains(collection.name)) {
            // In a target bucket: update or insert
            final idx =
                entries.indexWhere((e) => e?.media?.id == event.entry.mediaId);
            if (idx != -1) {
              entries[idx] = event.entry;
            } else {
              entries.insert(0, event.entry);
            }
            foundAny = true;
          } else {
            // Not a target: remove old copies
            entries.removeWhere((e) => e?.media?.id == event.entry.mediaId);
          }

          return collection.copyWith(entries: entries);
        }).toList() ??
        [];

    // For any custom bucket not in the original lists, create new one
    for (var bucket in targetBuckets) {
      if (!updatedLists.any((c) => c?.name == bucket)) {
        updatedLists.add(
          Query$MediaList$MediaListCollection$lists(
            name: bucket,
            entries: [event.entry],
          ),
        );
      }
    }

    // Commit to master
    _masterCollection = _masterCollection.copyWith(lists: updatedLists);

    // Emit filtered or full view
    final base = (filterApplied || searchApplied)
        ? _applyFilters(_masterCollection)
        : _masterCollection;
    emit(MediaListLoaded(listCollection: base));
  }

  void _onRemoveListEntry(RemoveListEntry event, Emitter<MediaListState> emit) {
    if (state is! MediaListLoaded) return;

    final updatedLists = _masterCollection.lists
            ?.map((collection) {
              if (collection == null) return null;
              final entries = List<Fragment$MediaListEntry?>.of(
                collection.entries ?? [],
              );
              entries.removeWhere((e) => e?.id == event.id);
              return collection.copyWith(entries: entries);
            })
            .where((c) => (c?.entries ?? []).isNotEmpty)
            .toList() ??
        [];
    _masterCollection = _masterCollection.copyWith(lists: updatedLists);

    final base = (filterApplied || searchApplied)
        ? _applyFilters(_masterCollection)
        : _masterCollection;
    emit(MediaListLoaded(listCollection: base));
  }

  void _onClearSearch(ClearSearch event, Emitter<MediaListState> emit) {
    if (type == Enum$MediaType.ANIME) {
      filter = (filter as AnimeFilter).copyWith(search: '');
    } else {
      filter = (filter as MangaFilter).copyWith(search: '');
    }
    searchApplied = false;
    final collection =
        filterApplied ? _applyFilters(_masterCollection) : _masterCollection;
    emit(MediaListLoaded(listCollection: collection));
  }

  void _onRemoveFilters(RemoveFilters event, Emitter<MediaListState> emit) {
    _selectedLists = [];
    filterApplied = false;
    final search = filter.search;
    filter = type == Enum$MediaType.ANIME
        ? AnimeFilter(sort: [Enum$MediaSort.UPDATED_AT_DESC], search: search)
        : MangaFilter(sort: [Enum$MediaSort.UPDATED_AT_DESC], search: search);
    final collection =
        searchApplied ? _masterCollection : _applyFilters(_masterCollection);
    emit(MediaListLoaded(listCollection: collection));
  }

  void setUserId(int userId) {
    this.userId = userId;
  }

  List<String> getUserLists() {
    return _masterCollection.lists?.map((e) => e?.name ?? '').toList() ?? [];
  }

  @override
  void onTransition(Transition<MediaListEvent, MediaListState> transition) {
    log(transition.toString(), name: 'MediaListBloc');
    super.onTransition(transition);
  }
}
