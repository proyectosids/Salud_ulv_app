import 'package:flutter/foundation.dart';
import 'package:salud_ulv_app/src/core/models/member.dart';
import 'package:salud_ulv_app/src/core/models/user.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/auth_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/user_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/services/check_connection_repo.dart';
// import 'package:salud_ulv_app/src/core/repositories/services/current_user_session.dart';
import 'package:salud_ulv_app/src/core/repositories/services/token_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/services/token_storage_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/use-cases/auth_usecase.dart';

class LoginUsecase implements ILoginUseCase {
  final IAuthExtRepo authRepo;
  final ITokenRepo tokenRepo;
  final ITokenStorageRepo tokenStorageRepo;
  final ICheckConnectionRepo checkConnectionRepo;
  final IUserLocalRepo userRepo;
  final IMemberLocalRepo memberLocalRepo;

  const LoginUsecase(
    this.authRepo,
    this.tokenRepo,
    this.tokenStorageRepo,
    this.checkConnectionRepo,
    this.userRepo,
    this.memberLocalRepo,
  );

  @override
  Future<void> execute(String input, String password) async {
    final hasConnection = await checkConnectionRepo.hasConnection();
    if (!hasConnection) throw Exception("No internet");

    final token = await authRepo.loginWithEmailOrCode(input, password);

    if (token == null || token.isEmpty) return;

    // final data = tokenRepo.decode(token);

    // final user = User(
    //   userUUID: data['uuid'],
    //   userCode: data['userCode'],
    //   email: data['email'],
    //   // currentRole: data['currentRole'],
    //   roles: data['roles'],
    //   );

    debugPrint('saving token');
    await tokenStorageRepo.saveUserToken(token);
    final data = tokenRepo.decode(token);
    debugPrint('decoding token');

    final tokenUser = data['user'];
    final groupID = data['groupID'];
    final typeID = data['typeID'];
    final roles = (data['roles'] as List).cast<String>();
    final userUUID = tokenUser['userUUID'];
    final user = User(
      userUUID: userUUID,
      userCode: tokenUser['userCode'],
      firstname: tokenUser['firstname'],
      surname: tokenUser['surname'],
      lastname: tokenUser['lastname'],
      email: tokenUser['email'],
      currentRole: roles[0],
      roles: roles,
      createdAt: DateTime.parse(tokenUser['createdAt'] as String),
    );

    debugPrint(user.userUUID);
    debugPrint(user.userCode);
    debugPrint(user.firstname);
    debugPrint(user.surname);
    debugPrint(user.lastname);
    debugPrint(user.email);
    debugPrint(user.currentRole);
    debugPrint(user.roles.toString());
    debugPrint(user.createdAt!.toIso8601String());

    // debugPrint(user.currentRole);

    debugPrint('before checking useruuid');
    if (user.userUUID == null) return;
    // save user from token data
    debugPrint('saving user locally');
    await userRepo.save(user);

    // await userRepo.setCurrentRole(userUUID!, roles[0]);
    // debugPrint("current role set [--------------------------DEBUG--------------------------]");
    // await userRepo.setRoles(userUUID, roles);

    final memberInfo = MemberInfo(
      userUUID: user.userUUID,
      groupID: groupID,
      typeID: typeID,
    );

    debugPrint('saving member info locally');
    await memberLocalRepo.saveInfo(memberInfo);

    return;
  }
}
