import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:otaku_world/constants/string_constants.dart';
import 'package:otaku_world/core/types/enums.dart';
import 'package:otaku_world/graphql/__generated/graphql/schema.graphql.dart';
import 'package:otaku_world/graphql/__generated/graphql/user/update_user.graphql.dart';
import 'package:otaku_world/graphql/__generated/graphql/user/viewer.graphql.dart';

import '../../graphql/__generated/graphql/fragments.graphql.dart';

part 'viewer_event.dart';
part 'viewer_state.dart';

class ViewerBloc extends Bloc<ViewerEvent, ViewerState> {
  ViewerBloc() : super(ViewerInitial()) {
    on<LoadViewer>(_onLoadViewer);
    on<UpdateUser>(_onUpdateUser);
  }

  bool showProcess = false;
  Query$Viewer$Viewer? user;

  Future<void> _onLoadViewer(
    LoadViewer event,
    Emitter<ViewerState> emit,
  ) async {
    log('Fetching user data');
    emit(ViewerLoading());
    final response = await event.client.query$Viewer(
      Options$Query$Viewer(
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    log('Response: $response');

    if (response.hasException) {
      if (state is ViewerLoaded) {
        return;
      }

      if (response.exception!.linkException != null) {
        emit(
          const ViewerError(
            type: ErrorType.noInternet,
            message: StringConstants.noInternetError,
          ),
        );
      } else {
        emit(
          const ViewerError(
            type: ErrorType.noInternet,
            message: StringConstants.unexpectedError,
          ),
        );
      }
    } else {
      final user = response.parsedData?.Viewer;
      if (user == null) {
        emit(
          const ViewerError(
            type: ErrorType.noInternet,
            message: StringConstants.unexpectedError,
          ),
        );
      } else {
        emit(ViewerLoaded(user: user));
      }
    }
  }

  Future<void> _onUpdateUser(
    UpdateUser event,
    Emitter<ViewerState> emit,
  ) async {
    final options = event.user.options;
    final mediaListOptions = event.user.mediaListOptions;
    log('List options: ${event.user.mediaListOptions?.animeList}');
    log('Options: ${options?.activityMergeTime}');
    emit((state as ViewerLoaded).copyWith(showProcess: true));

    final response = await event.client.mutate$UpdateUser(
      Options$Mutation$UpdateUser(
        variables: Variables$Mutation$UpdateUser(
          animeListOptions: mediaListOptions?.animeList != null
              ? Input$MediaListOptionsInput(
                  splitCompletedSectionByFormat: mediaListOptions
                      ?.animeList?.splitCompletedSectionByFormat,
                  advancedScoringEnabled:
                      mediaListOptions?.animeList?.advancedScoringEnabled,
                  advancedScoring: mediaListOptions?.animeList?.advancedScoring,
                  customLists: mediaListOptions?.animeList?.customLists,
                  sectionOrder: mediaListOptions?.animeList?.sectionOrder,
                )
              : null,
          mangaListOptions: mediaListOptions?.mangaList != null
              ? Input$MediaListOptionsInput(
                  splitCompletedSectionByFormat: mediaListOptions
                      ?.mangaList?.splitCompletedSectionByFormat,
                  advancedScoringEnabled:
                      mediaListOptions?.animeList?.advancedScoringEnabled,
                  advancedScoring: mediaListOptions?.animeList?.advancedScoring,
                  customLists: mediaListOptions?.mangaList?.customLists,
                  sectionOrder: mediaListOptions?.mangaList?.sectionOrder,
                )
              : null,
          titleLanguage: options?.titleLanguage,
          staffNameLanguage: options?.staffNameLanguage,
          activityMergeTime: options?.activityMergeTime,
          airingNotifications: options?.airingNotifications,
          displayAdultContent: options?.displayAdultContent,
          notificationOptions: options?.notificationOptions?.map(
            (e) {
              if (e == null) {
                return null;
              } else {
                return Input$NotificationOptionInput(
                  type: e.type,
                  enabled: e.enabled,
                );
              }
            },
          ).toList(),
          scoreFormat: mediaListOptions?.scoreFormat,
          rowOrder: mediaListOptions?.rowOrder,
          disabledListActivity: options?.disabledListActivity
              ?.map(
                (e) => Input$ListActivityOptionInput(
                  type: e?.type,
                  disabled: e?.disabled,
                ),
              )
              .toList(),
        ),
      ),
    );

    if (response.hasException) {
      if (response.exception!.linkException != null) {
        emit(
          (state as ViewerLoaded).copyWith(
            showProcess: false,
            showError: true,
            error: StringConstants.noInternetError,
          ),
        );
      } else {
        emit(
          (state as ViewerLoaded).copyWith(
            showProcess: false,
            showError: true,
            error: StringConstants.somethingWentWrongError,
          ),
        );
      }
    } else {
      emit(ViewerLoaded(user: response.parsedData!.UpdateUser!));
    }

    log('Response: ${response.parsedData?.UpdateUser?.options?.titleLanguage}');
  }

  @override
  void onTransition(Transition<ViewerEvent, ViewerState> transition) {
    log(transition.toString(), name: 'Viewer');
    super.onTransition(transition);
  }

  Fragment$Settings getUser() {
    return (state as ViewerLoaded).user;
  }

  Fragment$Settings? getNullableUser() {
    return (state is ViewerLoaded) ? (state as ViewerLoaded).user : null;
  }
}
