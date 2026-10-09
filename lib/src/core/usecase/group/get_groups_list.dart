
import 'package:flutter/foundation.dart';
import 'package:salud_ulv_app/src/core/models/group.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/group_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/user_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/services/check_connection_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/services/current_user_session_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/use-cases/group_usecases.dart';

class GetGroupsListUseCase implements IGetGroupListUseCase {
  final ICheckConnectionRepo checkConnectionRepo;
  final IGroupRepo groupRepo;
  final ICurrentUserSession currentUserSession;
  final IMemberLocalRepo memberLocalRepo;

  const GetGroupsListUseCase(
    this.checkConnectionRepo,
    this.groupRepo,
    this.currentUserSession,
    this.memberLocalRepo,
  );

  @override
  Future<List<IGroup>?> execute() async {
    final hasConnection = await checkConnectionRepo.hasConnection();
    if (!hasConnection) return null;

    final userUUID = await currentUserSession.getCurrentUserUUID();
    if (userUUID == null) return null;

    final userType = await memberLocalRepo.getMemberTypeID(userUUID);
    debugPrint("typeID use case $userType");
    if (userType == null) return null;

    final groupList = await groupRepo.getGroupsList(userType);

    if (groupList == null || groupList.isEmpty) {
      return null;
    }
    debugPrint("Lista de grupos en usecase: $groupList");

    return groupList;
  }
}
