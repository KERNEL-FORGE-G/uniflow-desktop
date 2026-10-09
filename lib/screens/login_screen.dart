import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_role.dart';
import '../providers/auth_provider.dart';
import '../repositories/auth_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/uni_icons.dart';
import '../widgets/app_text_field.dart';
import '../widgets/auth_chrome.dart';
import '../widgets/motion.dart';
import '../ui/app_button.dart';
import 'forgot_password_dialog.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';
import 'register_screen.dart';

/// Écran de connexion.
///
/// Le choix Compte universitaire / Compte indépendant est demandé en premier :
/// il ne change pas l'authentification (Appwrite ne connaît qu'un compte),
/// mais il est **vérifié** après connexion. Un compte universitaire qui se
/// connecte en « indépendant » est prévenu et redirigé vers son vrai espace :
/// c'est ce qui évite qu'un étudiant cherche ses cours dans un espace
/// personnel vide.
class LoginScreen extends ConsumerStatefulWidget {
 const LoginScreen({super.key});

 @override
 ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
 final _emailController = TextEditingController();
 final _passwordController = TextEditingController();

 AccountType _accountType = AccountType.university;
 bool _rememberMe = true;
 bool _isLoading = false;
 String? _errorMessage;
 String? _notice;

 int get _hour => DateTime.now().hour;

 @override
 void dispose() {
 _emailController.dispose();
 _passwordController.dispose();
 super.dispose();
 }

 Future<void> _handleLogin() async {
 if (_emailController.text.trim().isEmpty ||
 _passwordController.text.isEmpty) {
 setState(
 () => _errorMessage = 'Saisissez votre email et votre mot de passe.');
 return;
 }
 setState(() {
 _isLoading = true;
 _errorMessage = null;
 _notice = null;
 });

 try {
 final authRepo = ref.read(authRepositoryProvider);
 await authRepo.login(_emailController.text, _passwordController.text);
 final user = await authRepo.getCurrentUser();
 if (!mounted) return;
 if (user == null) {
 setState(() {
 _isLoading = false;
 _errorMessage =
 'Session ouverte, mais le compte n\'a pas pu être relu. '
 'Vérifiez la connexion réseau et réessayez.';
 });
 return;
 }

 // Le type choisi à l'écran n'est qu'une intention ; le type réel est
 // celui du compte. On le dit plutôt que d'ouvrir le mauvais espace.
 // Un compte `PLATFORM` entre par « Compte universitaire » : c'est
 // l'espace d'établissement, étendu à toutes les universités.
 final expected = _accountType == AccountType.university
 ? user.accountKind.seesInstitution
 : user.isPersonal;
 if (!expected) {
 _notice = user.isPersonal
 ? 'Ce compte est un compte indépendant : ouverture de votre espace personnel.'
 : 'Ce compte est rattaché à un établissement : ouverture de votre espace universitaire.';
 } else if (user.isPlatform) {
 _notice =
 'Administration de la plateforme : tous les établissements sont visibles.';
 }

 ref.read(currentUserProvider.notifier).state = user;
 ref.read(currentDestinationProvider.notifier).state = null;
 unawaited(
 ref.read(authRepositoryProvider).retryAcademicProvisioning(user));
 setState(() => _isLoading = false);
 if (_notice != null) {
 showFeedback(context,
 message: _notice!,
 success: true,
 duration: const Duration(seconds: 5));
 } else {
 showFeedback(context,
 message: 'Bienvenue, ${user.name}.', detail: user.userRole.scope);
 }
 Navigator.of(context).pushReplacement(softRoute(const MainShell()));
 } on AppwriteException catch (e) {
 if (!mounted) return;
 setState(() {
 _isLoading = false;
 _errorMessage = readableAuthError(e);
 });
 } catch (e) {
 if (!mounted) return;
 setState(() {
 _isLoading = false;
 _errorMessage = 'Connexion impossible : $e';
 });
 }
 }

 /// L'inscription mène elle-même au tableau de bord (et retire cet écran
 /// de la pile) ; ici, on ne fait qu'ouvrir le formulaire.
 void _openRegister() {
 Navigator.of(context).push(
 softRoute(RegisterScreen(initialType: _accountType)),
 );
 }

 @override
 Widget build(BuildContext context) {
 return AuthShell(form: _form());
 }

 Widget _form() {
 return Builder(builder: (context) {
 final scale = AuthScale.of(context);
 return _formBody(scale);
 });
 }

 Widget _formBody(AuthScale scale) {
 return Builder(builder: (context) => _formContent(context, scale));
 }

 Widget _formContent(BuildContext context, AuthScale scale) {
 final p = AuthTone.of(context);
 return Column(
 mainAxisSize: MainAxisSize.min,
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 Text(
 _hour < 6 ? 'Bonne nuit' : _hour < 12 ? 'Bonjour' : _hour < 18 ? 'Bon après-midi' : 'Bonsoir',
 key: const Key('auth-title'),
 textAlign: TextAlign.center,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: AppTextStyles.h1.copyWith(
 fontSize: scale.title,
 color: p.text,
 fontWeight: FontWeight.w800),
 ),
 const SizedBox(height: 6),
 Text(
 'Connectez-vous à votre espace UniFlow',
 textAlign: TextAlign.center,
 style: AppTextStyles.body
 .copyWith(fontSize: scale.body, color: p.textSoft),
 ),
 const SizedBox(height: 22),
 AccountTypeSelector(
 value: _accountType,
 onChanged: (type) => setState(() => _accountType = type),
 ),
 if (_errorMessage != null) ...[
 const SizedBox(height: 16),
 ErrorBanner(message: _errorMessage!),
 ],
 const SizedBox(height: 20),
 AppTextField(
 label: 'Email',
 hint: 'prenom.nom@universite.cm',
 controller: _emailController,
 keyboardType: TextInputType.emailAddress,
 prefixIcon: UniIcons.mail(UniIconStyle.bold),
 ),
 const SizedBox(height: 16),
 AppTextField(
 label: 'Mot de passe',
 hint: '••••••••',
 controller: _passwordController,
 obscureText: true,
 prefixIcon: UniIcons.lock(UniIconStyle.bold),
 ),
 const SizedBox(height: 12),
 Wrap(
 alignment: WrapAlignment.spaceBetween,
 crossAxisAlignment: WrapCrossAlignment.center,
 spacing: 16,
 runSpacing: 2,
 children: [
 InkWell(
 onTap: () => setState(() => _rememberMe = !_rememberMe),
 borderRadius: BorderRadius.circular(6),
 child: Padding(
 padding: const EdgeInsets.symmetric(vertical: 4),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 SizedBox(
 width: 18,
 height: 18,
 child: Checkbox(
 value: _rememberMe,
 onChanged: (v) =>
 setState(() => _rememberMe = v ?? false),
 activeColor: AppColors.primaryBlue,
 materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
 visualDensity: VisualDensity.compact,
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(4)),
 ),
 ),
 const SizedBox(width: 8),
 Flexible(
 child: Text(
 'Rester connecté',
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: TextStyle(fontSize: 13, color: p.textSoft),
 ),
 ),
 ],
 ),
 ),
 ),
 // Un lien, pas un bouton : le `TextButton` Material posait 8 px de
 // marge et une hauteur minimale de 40 px qui désalignaient la ligne
 // avec la case « Rester connecté ».
 InkWell(
 onTap: () => showForgotPasswordDialog(
 context,
 initialEmail: _emailController.text,
 ),
 borderRadius: BorderRadius.circular(6),
 child: Padding(
 padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
 child: Text('Mot de passe oublié ?', style: p.linkStyle),
 ),
 ),
 ],
 ),
 const SizedBox(height: 20),
 GradientButton(
 label: 'Se connecter',
 isLoading: _isLoading,
 onPressed: _isLoading ? null : _handleLogin,
 ),
 const SizedBox(height: 18),
 Row(
 children: [
 Expanded(child: Divider(color: p.divider)),
 Flexible(
 flex: 3,
 child: Padding(
 padding: const EdgeInsets.symmetric(horizontal: 8),
 child: Text(
 'Pas encore de compte ?',
 maxLines: 1,
 textAlign: TextAlign.center,
 overflow: TextOverflow.ellipsis,
 style: AppTextStyles.body.copyWith(
 fontSize: 12.0,
 color: p.textSoft,
 ),
 ),
 ),
 ),
 Expanded(child: Divider(color: p.divider)),
 ],
 ),
 const SizedBox(height: 14),
 AppButton.secondary(
 label: _accountType == AccountType.university
 ? 'Créer un compte étudiant'
 : 'Créer un compte indépendant',
 icon: UniIcons.addPerson(UniIconStyle.bold),
 expand: true,
 height: scale.field - 4,
 onPressed: _isLoading ? null : _openRegister,
 ),
 const SizedBox(height: 16),
 Row(children: [
 Expanded(child: Divider(color: p.divider)),
 Padding(
 padding: const EdgeInsets.symmetric(horizontal: 12),
 child: Text('ou',
 style: AppTextStyles.body
 .copyWith(fontSize: 12.5, color: p.muted)),
 ),
 Expanded(child: Divider(color: p.divider)),
 ]),
 const SizedBox(height: 14),
 _GoogleSignInButton(
 isLoading: _isLoading,
 onPressed: _isLoading ? null : _handleGoogleLogin,
 ),
 const SizedBox(height: 12),
 Center(
 child: InkWell(
 onTap: () {
 Navigator.of(context).push(
 MaterialPageRoute(builder: (_) => const OnboardingScreen()),
 );
 },
 borderRadius: BorderRadius.circular(6),
 child: Padding(
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
 child: FittedBox(
 fit: BoxFit.scaleDown,
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(Icons.auto_awesome_rounded, size: 16, color: p.link),
 const SizedBox(width: 6),
 Text(
 'Découvrir UniFlow (visite guidée)',
 style: TextStyle(
 fontSize: 12.5,
 color: p.link,
 fontWeight: FontWeight.w600,
 ),
 ),
 ],
 ),
 ),
 ),
 ),
 ),
 ],
 );
 }

 Future<void> _handleGoogleLogin() async {
 setState(() {
 _isLoading = true;
 _errorMessage = null;
 _notice = null;
 });
 try {
 final authRepo = ref.read(authRepositoryProvider);
 await authRepo.loginWithGoogle();
 final user = await authRepo.getCurrentUser();
 if (!mounted) return;
 if (user == null) {
 setState(() {
 _isLoading = false;
 _errorMessage =
 'Connexion Google réussie, mais le compte n\'a pas pu être relu. '
 'Vérifiez la connexion réseau et réessayez.';
 });
 return;
 }
 ref.read(currentUserProvider.notifier).state = user;
 ref.read(currentDestinationProvider.notifier).state = null;
 unawaited(
 ref.read(authRepositoryProvider).retryAcademicProvisioning(user));
 setState(() => _isLoading = false);
 showFeedback(context,
 message: 'Bienvenue, ${user.name}.', detail: user.userRole.scope);
 Navigator.of(context).pushReplacement(softRoute(const MainShell()));
 } on AppwriteException catch (e) {
 if (!mounted) return;
 setState(() {
 _isLoading = false;
 _errorMessage = readableAuthError(e);
 });
 } catch (e) {
 if (!mounted) return;
 setState(() {
 _isLoading = false;
 _errorMessage = 'Connexion Google impossible : $e';
 });
 }
 }
}

/// Bouton "Continuer avec Google" adapté au thème desktop UniFlow.
class _GoogleSignInButton extends StatelessWidget {
 final bool isLoading;
 final VoidCallback? onPressed;
 const _GoogleSignInButton({required this.isLoading, required this.onPressed});

 @override
 Widget build(BuildContext context) {
 final dark = AuthTone.of(context).dark;
 return Material(
 color: AppColors.cardWhite,
 borderRadius: BorderRadius.circular(dark ? 999 : 10),
 child: InkWell(
 onTap: onPressed,
 borderRadius: BorderRadius.circular(dark ? 999 : 10),
 child: Container(
 width: double.infinity,
 height: 44,
 decoration: BoxDecoration(
 borderRadius: BorderRadius.circular(dark ? 999 : 10),
 border: Border.all(
 color: dark ? Colors.transparent : AppColors.inputBorder,
 ),
 ),
 child: Center(
 child: isLoading
 ? const SizedBox(
 width: 18,
 height: 18,
 child: CircularProgressIndicator(strokeWidth: 2),
 )
 : FittedBox(
 fit: BoxFit.scaleDown,
 child: Row(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 SizedBox(
 width: 20,
 height: 20,
 child: CustomPaint(painter: _GoogleLogoPainter()),
 ),
 const SizedBox(width: 10),
 const Text(
 'Continuer avec Google',
 style: TextStyle(
 fontSize: 14,
 fontWeight: FontWeight.w500,
 color: AppColors.textPrimary,
 ),
 ),
 ],
 ),
 ),
 ),
 ),
 ),
 );
 }
}

class _GoogleLogoPainter extends CustomPainter {
 @override
 void paint(Canvas canvas, Size s) {
 final c = Offset(s.width / 2, s.height / 2);
 final r = s.width / 2;
 final p = Paint()
 ..style = PaintingStyle.stroke
 ..strokeWidth = r * 0.35
 ..strokeCap = StrokeCap.round;
 p.color = const Color(0xFF4285F4);
 canvas.drawArc(
 Rect.fromCircle(center: c, radius: r * 0.65), -0.30, 1.55, false, p);
 p.color = const Color(0xFFEA4335);
 canvas.drawArc(
 Rect.fromCircle(center: c, radius: r * 0.65), -1.90, 1.00, false, p);
 p.color = const Color(0xFFFBBC05);
 canvas.drawArc(
 Rect.fromCircle(center: c, radius: r * 0.65), 2.10, 0.90, false, p);
 p.color = const Color(0xFF34A853);
 canvas.drawArc(
 Rect.fromCircle(center: c, radius: r * 0.65), 3.00, 0.45, false, p);
 p
 ..style = PaintingStyle.fill
 ..color = const Color(0xFF4285F4);
 canvas.drawRect(
 Rect.fromLTWH(c.dx, c.dy - r * 0.12, r * 0.65, r * 0.24), p);
 }

 @override
 bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Traduit les codes d'erreur Appwrite en messages compréhensibles.
///
/// Un échec réseau et un mauvais mot de passe ne doivent pas être confondus :
/// c'est ce qui rendait le diagnostic impossible jusqu'ici.
String readableAuthError(AppwriteException e) {
 switch (e.code) {
 case 401:
 return 'Email ou mot de passe incorrect.';
 case 403:
 return 'Accès refusé : cette plateforme n\'est pas autorisée dans le projet '
 'Appwrite. Ajoutez son identifiant dans Overview → Platforms.';
 case 409:
 return 'Un compte existe déjà avec cet email. Connectez-vous, ou utilisez '
 '« Mot de passe oublié ».';
 case 429:
 return 'Trop de tentatives. Réessayez dans quelques minutes.';
 default:
 final message = e.message ?? '';
 if (message.contains('Failed host lookup') ||
 message.contains('Connection') ||
 message.contains('SocketException') ||
 message.contains('timed out')) {
 return 'Appwrite est injoignable. Vérifiez votre connexion internet et réessayez.';
 }
 return message.isEmpty ? 'Erreur Appwrite (code ${e.code}).' : message;
 }
}
