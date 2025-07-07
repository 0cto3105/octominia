// lib/widgets/custom_expansion_panel.dart
import 'package:flutter/material.dart';

// Nouveau widget personnalisé pour remplacer ExpansionTile
class CustomExpansionPanel extends StatefulWidget {
  final Widget header; // C'est le widget Text que vous passez
  final Widget content;
  final bool initiallyExpanded; // Cette propriété sera maintenant utilisée pour l'état initial
  final double headerHeight; // Hauteur fixe du header
  final String? imageUrl; // Pour le background (maintenant local)
  final bool isOrder; // Pour les opacités d'image
  final EdgeInsetsGeometry? margin; // Rend la marge optionnelle
  final BorderRadiusGeometry? borderRadius; // Nouvelle propriété pour le borderRadius

  // Callback pour notifier le parent de l'état d'expansion (pour les ordres)
  final ValueChanged<bool>? onExpansionChanged;
  // NOUVEAU : Callback pour un tap sur l'en-tête (pour la navigation des factions)
  final VoidCallback? onHeaderTap;

  const CustomExpansionPanel({
    super.key,
    required this.header,
    required this.content,
    this.initiallyExpanded = false,
    required this.headerHeight,
    this.imageUrl,
    this.isOrder = false,
    this.margin,
    this.borderRadius, // Accepte un borderRadius personnalisé
    this.onExpansionChanged, // Initialise le callback
    this.onHeaderTap, // Initialise le nouveau callback
  });

  @override
  State<CustomExpansionPanel> createState() => _CustomExpansionPanelState();
}

class _CustomExpansionPanelState extends State<CustomExpansionPanel> {
  late bool _isExpanded; // Changez en late pour l'initialisation dans initState

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded; // Utilise la valeur passée
  }

  // Nouvelle méthode pour gérer le tap sur l'en-tête
  void _handleTap() {
    if (widget.onHeaderTap != null) {
      widget.onHeaderTap!(); // Si onHeaderTap est fourni, l'appeler
    } else {
      _toggleExpansion(); // Sinon, utiliser le comportement d'expansion par défaut
    }
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    // Appelle le callback si fourni
    widget.onExpansionChanged?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: widget.borderRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          GestureDetector(
            onTap: _handleTap, // Utilise la nouvelle méthode _handleTap
            child: Container(
              padding: EdgeInsets.zero,
              height: widget.headerHeight,
              color: Colors.transparent,
              child: Stack(
                children: [
                  // L'image de fond
                  if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                    Positioned.fill(
                      child: Image.asset(
                        widget.imageUrl!,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        colorBlendMode: BlendMode.darken,
                        color: Colors.black.withOpacity(widget.isOrder ? 0.3 : 0.4),
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  // L'overlay dégradé noir sur l'image (pour assombrir)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xCC000000), // HEX pour Colors.black.withOpacity(0.8)
                            Color(0xB3000000), // HEX pour Colors.black.withOpacity(0.7)
                            Color(0x00000000), // HEX pour Colors.black.withOpacity(0.0)
                          ],
                          stops: [0.0, 0.4, 0.7],
                        ),
                      ),
                    ),
                  ),
                  // Le texte de l'en-tête
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: widget.header,
                    ),
                  ),
                  // L'icône d'expansion (masquée si onHeaderTap est fourni)
                  if (widget.onHeaderTap == null) // Affiche l'icône seulement si onHeaderTap n'est PAS fourni
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(50.0),
                          ),
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 36,
                            shadows: const [
                              Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Le contenu expansible
          AnimatedCrossFade(
            firstChild: Container(height: 0.0),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: widget.content,
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}