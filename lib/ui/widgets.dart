import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/photo.dart';
import '../state/app_state.dart';
import 'theme.dart';

class LineIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  const LineIcon(this.name, {super.key, this.size = 22, this.color});
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icons/$name.svg',
    width: size,
    height: size,
    colorFilter: ColorFilter.mode(
      color ?? Theme.of(context).colorScheme.onSurface,
      BlendMode.srcIn,
    ),
  );
}

class IconAction extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final Color? background;
  final Color? color;
  const IconAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 44,
    this.iconSize = 22,
    this.background,
    this.color,
  });
  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Semantics(
      button: true,
      label: label,
      child: Material(
        color: background ?? Colors.transparent,
        borderRadius: BorderRadius.circular(size == 32 ? 10 : 12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: LineIcon(icon, size: iconSize, color: color),
            ),
          ),
        ),
      ),
    ),
  );
}

class ImagoButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final String? icon;
  final bool primary;
  final bool busy;
  final double height;
  const ImagoButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.primary = true,
    this.busy = false,
    this.height = 48,
  });
  @override
  Widget build(BuildContext context) {
    final ink = primary
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      height: height,
      child: Material(
        color: primary
            ? ImagoColors.brand.withValues(
                alpha: onPressed == null && !busy ? .45 : 1,
              )
            : Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: primary
              ? BorderSide.none
              : BorderSide(color: Theme.of(context).dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy ? null : onPressed,
          child: Semantics(
            button: true,
            enabled: onPressed != null,
            label: label,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (busy) ...[
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ink,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else if (icon != null) ...[
                    LineIcon(icon!, size: 18, color: ink),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ink,
                        fontSize: 13,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                      ),
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

class FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final double height;
  const FilterChipButton(
    this.label, {
    super.key,
    this.selected = false,
    this.onTap,
    this.height = 32,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? softColor(context) : panelColor(context),
    borderRadius: BorderRadius.circular(10),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            height: 1.2,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? ImagoColors.brand : ImagoColors.muted,
          ),
        ),
      ),
    ),
  );
}

class LabeledField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscure;
  final Widget? suffix;
  final Widget? prefix;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  final int? maxLength;
  final int maxLines;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final void Function(String)? onSubmitted;
  const LabeledField(
    this.label, {
    super.key,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.suffix,
    this.prefix,
    this.keyboard,
    this.validator,
    this.maxLength,
    this.maxLines = 1,
    this.enabled = true,
    this.autofillHints,
    this.onSubmitted,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          height: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 9),
      TextFormField(
        controller: controller,
        keyboardType: keyboard,
        enabled: enabled,
        obscureText: obscure,
        maxLines: maxLines,
        maxLength: maxLength,
        validator: validator,
        autofillHints: autofillHints,
        onFieldSubmitted: onSubmitted,
        textInputAction: onSubmitted == null
            ? TextInputAction.next
            : TextInputAction.done,
        style: const TextStyle(fontSize: 14, height: 1.4),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: prefix,
          suffixIcon: suffix,
          prefixIconConstraints: const BoxConstraints(minWidth: 42),
          suffixIconConstraints: const BoxConstraints(minWidth: 42),
          counterStyle: const TextStyle(fontSize: 10, color: ImagoColors.muted),
        ),
      ),
    ],
  );
}

class PageHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  const PageHeading(this.title, this.subtitle, {super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: ImagoColors.muted,
          height: 1.45,
        ),
      ),
    ],
  );
}

class ContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final bool center;
  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = 1120,
    this.center = true,
  });
  @override
  Widget build(BuildContext context) => Align(
    alignment: center ? Alignment.topCenter : Alignment.topLeft,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

void showMessage(BuildContext context, String message, {bool error = false}) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      backgroundColor: error ? const Color(0xFFAE3345) : ImagoColors.rail,
      duration: Duration(seconds: error ? 6 : 3),
    ),
  );
}

Future<void> openCredit(BuildContext context, String? url) async {
  if (url == null) return;
  try {
    final uri = Uri.parse(url);
    final target = uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        'utm_source': 'imagohub',
        'utm_medium': 'referral',
      },
    );
    if (!await launchUrl(target, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        showMessage(context, 'Não foi possível abrir o link.', error: true);
      }
    }
  } catch (_) {
    if (context.mounted) {
      showMessage(context, 'Não foi possível abrir o link.', error: true);
    }
  }
}

class PhotoImage extends StatelessWidget {
  final Photo photo;
  final bool dataSaver;
  final int imageWidth;
  final double? ratio;
  const PhotoImage(
    this.photo, {
    super.key,
    this.dataSaver = false,
    this.imageWidth = 800,
    this.ratio,
  });
  @override
  Widget build(BuildContext context) {
    final fallback = photo.asset == null
        ? ColoredBox(
            color: photo.placeholder,
            child: const Center(
              child: LineIcon('Image', color: Colors.white, size: 32),
            ),
          )
        : Image.asset(
            photo.asset!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
    const referenceMode = bool.fromEnvironment(
      'REFERENCE_MODE',
      defaultValue: false,
    );
    if (referenceMode && photo.asset != null) return fallback;
    final width = dataSaver ? imageWidth ~/ 2 : imageWidth;
    return Image.network(
      photo.imageUrl(
        width: width,
        height: ratio == null ? null : (width / ratio!).round(),
        dataSaver: dataSaver,
      ),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      frameBuilder: (context, image, frame, sync) =>
          frame == null ? fallback : image,
      errorBuilder: (context, error, stack) => fallback,
    );
  }
}

class PhotoCard extends StatelessWidget {
  final Photo photo;
  final AppState state;
  final bool compact;
  final double? imageHeight;
  final double? imageRatio;
  final bool selected;
  final bool selecting;
  final VoidCallback? onSelect;
  final VoidCallback? onLongPress;
  const PhotoCard(
    this.photo, {
    super.key,
    required this.state,
    this.compact = false,
    this.imageHeight,
    this.imageRatio,
    this.selected = false,
    this.selecting = false,
    this.onSelect,
    this.onLongPress,
  });
  @override
  Widget build(BuildContext context) {
    final favorite = state.favorites.contains(photo.id);
    return Material(
      color: selected
          ? softColor(context)
          : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? ImagoColors.brand : Theme.of(context).dividerColor,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: selecting ? onSelect : () => state.openPhoto(photo),
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: imageHeight ?? (compact ? 168 : 226),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PhotoImage(
                    photo,
                    dataSaver: state.dataSaver,
                    ratio: imageRatio,
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: IconAction(
                      icon: 'Star',
                      label: favorite
                          ? 'Remover ${photo.title} dos favoritos'
                          : 'Favoritar ${photo.title}',
                      size: 32,
                      iconSize: 22,
                      color: ImagoColors.ink,
                      background: favorite ? ImagoColors.star : Colors.white,
                      onTap: () async {
                        try {
                          await state.toggleFavorite(photo);
                        } catch (_) {
                          if (context.mounted) {
                            showMessage(
                              context,
                              'Favorito salvo no dispositivo. Não foi possível registrar o uso na Unsplash.',
                              error: true,
                            );
                          }
                        }
                      },
                    ),
                  ),
                  if (selecting)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Semantics(
                        label: 'Selecionar ${photo.title}',
                        selected: selected,
                        button: true,
                        child: GestureDetector(
                          onTap: onSelect,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: selected
                                  ? ImagoColors.brand
                                  : Colors.white.withValues(alpha: .92),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? ImagoColors.brand
                                    : ImagoColors.line,
                              ),
                            ),
                            child: selected
                                ? const Center(
                                    child: LineIcon(
                                      'Check',
                                      size: 17,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 10 : 12,
                12,
                compact ? 10 : 12,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    photo.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 12 : 14,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () =>
                        openCredit(context, photo.user['links']?['html']),
                    child: Text(
                      photo.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 10 : 12,
                        color: ImagoColors.muted,
                        height: 1.25,
                      ),
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 3),
                    GestureDetector(
                      onTap: () => openCredit(context, 'https://unsplash.com'),
                      child: const Text(
                        'na Unsplash ↗',
                        style: TextStyle(
                          fontSize: 10,
                          color: ImagoColors.muted,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InlineError extends StatelessWidget {
  final String message;
  final VoidCallback? retry;
  const InlineError(this.message, {super.key, this.retry});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: panelColor(context),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        const LineIcon('AlertCircle', color: ImagoColors.muted),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: ImagoColors.muted),
        ),
        if (retry != null)
          TextButton(onPressed: retry, child: const Text('Tentar novamente')),
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  final String icon;
  final String title;
  final String message;
  final Widget? action;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
    child: Column(
      children: [
        LineIcon(icon, size: 38, color: ImagoColors.brand),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: ImagoColors.muted),
        ),
        if (action != null) ...[const SizedBox(height: 20), action!],
      ],
    ),
  );
}
