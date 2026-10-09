
import 'package:flutter/rendering.dart';
import 'package:salud_ulv_app/src/core/models/roles.dart';
import 'package:salud_ulv_app/src/core/models/user.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/user_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/services/current_user_session_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/use-cases/profile_usecase.dart';

class GetProfileInfoUsecase implements IGetProfileInfoUsecase{
  // final IUsersLocalRepo localRepo;
  final IUserLocalRepo userLocalRepo;
  final IMemberLocalRepo memberLocalRepo;
  final ICurrentUserSession currentUserSession;

  const GetProfileInfoUsecase(this.userLocalRepo, this.currentUserSession, this.memberLocalRepo);

  @override
  Future<IUser?> execute() async {
    final userUUID = await currentUserSession.getCurrentUserUUID();
    if(userUUID == null) return null;

    // final role = await userLocalRepo.getCurrentRole(userUUID);
    // final currentRole = role.toUserRole();


    final role = await userLocalRepo.getCurrentRole(userUUID);
   debugPrint('role type: ${role.runtimeType}'); // <-- is this actually "String" or "Null"?
   final currentRole = role.toUserRole();
   debugPrint('currentRole type: ${currentRole.runtimeType}');
    debugPrint('Loading user profile: $currentRole');
   
    if(currentRole == UserRole.member){
      debugPrint('returning member');
      // final member = await memberLocalRepo.getUser(userUUID);
      // final member = await memberLocalRepo.getUser(userUUID);
      final member = await memberLocalRepo.getUser(userUUID);
      debugPrint('Returning member profile');
      return member;
    }
    // ignore: unrelated_type_equality_checks
    else if(currentRole == UserRole.admin){
      final admin = await userLocalRepo.getUser(userUUID);
      debugPrint('Returning admin profile');
      return admin;
    }
    else {
      debugPrint('returning user');
      final user = await userLocalRepo.getUser(userUUID);
      debugPrint('Returning user profile');
      return user;

    }  
  }
}