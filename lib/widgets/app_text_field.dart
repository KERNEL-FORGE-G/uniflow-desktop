import 'package:flutter/material.dart';
import 'auth_tone.dart';
import 'uni_icons.dart';

/// Champ de saisie custom réutilisé sur tous les formulaires de l'app
/// (login, création d'étudiant, d'enseignant, etc.)
///
/// Affiche : un label au-dessus, un champ stylé (fond gris clair, bordure
/// qui devient bleue au focus), une icône optionnelle à gauche, et un
/// bouton "œil" pour afficher/masquer le texte si c'est un champ mot de passe.
class AppTextField extends StatefulWidget {
  final String label; // texte affiché au-dessus du champ (ex: "Email")
  final String
      hint; // texte d'exemple affiché en placeholder (ex: "admin@uniflow.edu")
  final bool obscureText; // true = champ mot de passe (texte masqué par défaut)
  final IconData? prefixIcon; // icône optionnelle à gauche du texte saisi
  final TextEditingController?
      controller; // pour récupérer/contrôler la valeur saisie
  final TextInputType keyboardType; // type de clavier (texte, email, etc.)

  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.prefixIcon,
    this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  // Etat local qui suit si le texte est actuellement masqué ou visible.
  // Initialisé à la valeur de obscureText passée par le parent,
  // puis modifiable indépendamment via le bouton "œil".
  late bool _obscure = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final p = AuthTone.of(context);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(p.fieldRadius),
          borderSide: BorderSide(color: color, width: width),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label au-dessus du champ (ex: "Mot de passe")
        Text(widget.label, style: p.label),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          cursorColor: p.focus,
          style: TextStyle(fontSize: 14, color: p.text),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(fontSize: 14, color: p.muted),
            filled: true,
            fillColor: p.fill, // fond du champ (gris clair ou bleu nuit)
            // icône à gauche (ex: enveloppe pour l'email, cadenas pour le mot de passe)
            prefixIcon: widget.prefixIcon != null
                ? PhosphorIcon(widget.prefixIcon!, size: 20, color: p.muted)
                : null,
            // bouton "œil" affiché uniquement si c'est un champ mot de passe,
            // permet de basculer entre texte masqué / visible
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: PhosphorIcon(
                      _obscure
                          ? UniIcons.eyeOff(UniIconStyle.bold)
                          : UniIcons.eye(UniIconStyle.bold),
                      size: 20,
                      color: p.muted,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            // Bordure par défaut (état neutre, ni focus ni erreur)
            border: border(p.border),
            enabledBorder: border(p.border),
            // Bordure d'accent plus épaisse au focus, pour un feedback clair
            focusedBorder: border(p.focus, 1.5),
          ),
        ),
      ],
    );
  }
}
