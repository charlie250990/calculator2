import 'package:calculator/helpers/utils.dart';
import 'package:calculator/logic/cubits/calculation/calculation_cubit.dart';
import 'package:calculator/logic/cubits/history/history_cubit.dart';
import 'package:calculator/logic/cubits/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class ButtonModel {
  final String operator;
  final String? tooltip;
  final double size;
  final bool isBold;
  final bool isPortrait;

  ButtonModel({
    required this.operator,
    this.tooltip,
    this.size = 26.0,
    this.isBold = false,
    this.isPortrait = true,
  });
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const String routeName = '/';

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<ButtonModel> buttons = [
    ButtonModel(operator: 'C', tooltip: 'Clear'),
    ButtonModel(operator: '()', tooltip: 'Brackets'),
    ButtonModel(operator: '%', tooltip: 'Percentage', isBold: true),
    ButtonModel(operator: '÷', tooltip: 'Division', size: 32.0, isBold: true),
    ButtonModel(operator: '7'),
    ButtonModel(operator: '8'),
    ButtonModel(operator: '9'),
    ButtonModel(
      operator: '×',
      tooltip: 'Multiplication',
      size: 32.0,
      isBold: true,
    ),
    ButtonModel(operator: '4'),
    ButtonModel(operator: '5'),
    ButtonModel(operator: '6'),
    ButtonModel(operator: '-', tooltip: 'Minus', size: 32.0, isBold: true),
    ButtonModel(operator: '1'),
    ButtonModel(operator: '2'),
    ButtonModel(operator: '3'),
    ButtonModel(operator: '+', tooltip: 'Plus', size: 32.0, isBold: true),
    ButtonModel(operator: '+/-'),
    ButtonModel(operator: '0'),
    ButtonModel(operator: '.'),
    ButtonModel(operator: '=', tooltip: 'Equal', size: 32.0, isBold: true),
  ];

  @override
  void initState() {
    super.initState();
    _controller.text = context.read<CalculationCubit>().state.question;
    _controller.addListener(() {
      context.read<CalculationCubit>().onUpdateCursorPosition(_controller.selection.baseOffset);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setTheme() {
    HapticFeedback.mediumImpact();
    context.read<ThemeCubit>().onToggleTheme();
    setState(() {}); // Trigger a rebuild to apply the new theme
  }

  @override
  Widget build(BuildContext context) {
    final histories = context.select((HistoryCubit cubit) => cubit.state).reversed.toList();
    final calculationState = context.select((CalculationCubit cubit) => cubit.state);
    final question = calculationState.question;
    final answer = calculationState.answer;
    final increase1 = calculationState.increase1;
    final increase2 = calculationState.increase2;
    final isInitial = calculationState.isInitial;
    final themeMode = context.select((ThemeCubit cubit) => cubit.state);
    final themeIcon = themeMode == ThemeMode.light ? Icons.brightness_4_rounded : Icons.brightness_5_rounded;

    final cursorPosition = calculationState.cursorPosition ?? question.length;
    _controller.text = question;
    if (cursorPosition <= _controller.text.length) {
      _controller.selection = TextSelection.fromPosition(TextPosition(offset: cursorPosition));
    }

    return BlocListener<CalculationCubit, CalculationState>(
      listener: (context, state) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.ease,
        );
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: GestureDetector(
                            onTapUp: (details) {
                              final RenderBox renderBox = context.findRenderObject() as RenderBox;
                              final offset = renderBox.globalToLocal(details.globalPosition);
                              final textPainter = TextPainter(
                                text: TextSpan(
                                  text: _controller.text,
                                  style: TextStyle(
                                    fontSize: increase1
                                        ? increase2
                                            ? 26.0
                                            : 28.0
                                        : 40.0,
                                  ),
                                ),
                                textDirection: TextDirection.ltr,
                              );
                              textPainter.layout();
                              final position = textPainter.getPositionForOffset(offset);
                              _controller.selection = TextSelection.fromPosition(position);
                              _focusNode.requestFocus();
                            },
                            child: TextField(
                              maxLines: null,
                              cursorColor: const Color.fromARGB(255, 39, 45, 54),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(0),
                              ),
                              controller: _controller,
                              focusNode: _focusNode,
                              textAlign: TextAlign.end,
                              readOnly: true,
                              showCursor: true,
                              style: TextStyle(
                                fontSize: increase1
                                    ? increase2
                                        ? 26.0
                                        : 28.0
                                    : 40.0,
                              ),
                              onChanged: (value) {
                                context.read<CalculationCubit>().onUpdateQuestion(value);
                              },
                            ),
                          ),
                        ),
                      ),
                      if (answer != null && !['÷', '×', '+', '-'].contains(_controller.text.trim().isNotEmpty ? _controller.text.trim().characters.last : ''))
                      Padding(
                        padding: const EdgeInsets.only(top: 22.0),
                        child: SelectableText.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: Utils.formatAmount(
                                    answer.toString().length > 15
                                        ? answer.toStringAsExponential(8)
                                        : answer.toString()),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontSize: 32.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Tooltip(
                                message: 'History',
                                child: IconButton(
                                  splashRadius: 20.0,
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    showModalBottomSheet(
                                      context: context,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                      ),
                                      builder: (BuildContext context) {
                                        return Container(
                                          decoration: const BoxDecoration(
                                            borderRadius: BorderRadius.all(Radius.circular(20)),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 20),
                                          height: MediaQuery.of(context).size.height * 0.9,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Flexible(
                                                child: ShaderMask(
                                                  shaderCallback: (Rect bounds) {
                                                    return const LinearGradient(
                                                      begin: Alignment.topCenter,
                                                      end: Alignment.bottomCenter,
                                                      colors: [Colors.transparent, Color.fromARGB(255, 0, 0, 0)],
                                                      stops: [0.0, 0.5],
                                                    ).createShader(bounds);
                                                  },
                                                  blendMode: BlendMode.dstIn,
                                                  child: ListView.separated(
                                                    reverse: true,
                                                    separatorBuilder: (context, index) =>
                                                        const SizedBox(height: 25),
                                                    itemCount: histories.length,
                                                    itemBuilder: (context, index) {
                                                      final calculcation = histories[index];
                                                      final question = calculcation.question;
                                                      final answer = calculcation.answer;
                                                      final answerString = answer != null
                                                          ? answer.toString().length > 15
                                                              ? answer.toStringAsExponential(8)
                                                              : answer.toString()
                                                          : null;
                                
                                                      return Column(
                                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                                        children: [
                                                          Material(
                                                            color: Colors.transparent,
                                                            child: InkWell(
                                                              onTap: () =>
                                                                  context.read<CalculationCubit>().onAdd(question),
                                                              child: ClipRRect(
                                                                borderRadius: BorderRadius.circular(20),
                                                                child: Text(
                                                                  question,
                                                                  style: const TextStyle(
                                                                    fontSize: 16,
                                                                  ),
                                                                  textAlign: TextAlign.end,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          if (answer != null && answerString != null) ...[
                                                            const SizedBox(height: 5),
                                                            Material(
                                                              color: Colors.transparent,
                                                              child: InkWell(
                                                                onTap: () => context
                                                                    .read<CalculationCubit>()
                                                                    .onAdd(answer.toString()),
                                                                child: ClipRRect(
                                                                  borderRadius: BorderRadius.circular(20),
                                                                  child: Text(
                                                                    '=${Utils.formatAmount(answerString)}',
                                                                    style: const TextStyle(
                                                                      fontSize: 16,
                                                                    ),
                                                                    textAlign: TextAlign.end,
                                                                    overflow: TextOverflow.ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      );
                                                    },
                                                  ),
                                                )
                                              ),
                                              const SizedBox(height: 15),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        context.read<HistoryCubit>().onClear();
                                                        Navigator.pop(context);
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: const Color.fromARGB(255, 39, 45, 54),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(50),
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        'Clear History',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: const Color.fromARGB(255, 39, 45, 54),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(50),
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        'Close History',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 20),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  icon: const Icon(Icons.history_rounded),
                                ),
                              ),
                              Tooltip(
                                message: 'Info',
                                child: IconButton(
                                  splashRadius: 20.0,
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(20),
                                            ),
                                          ),
                                          content: SizedBox(
                                            height: 305,
                                            child: Column(
                                              children: [
                                                const ClipOval(
                                                  child: Image(
                                                    height: 70,
                                                    width: 70,
                                                    image: AssetImage(
                                                      'assets/images/icon.png',
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  'Find more amazing Mini Apps:'.toUpperCase(),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color.fromARGB(255, 39, 45, 54),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(50),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    HapticFeedback.mediumImpact();
                                                    launchUrl(Uri.parse('https://cafi.one/miniapps'));
                                                  },
                                                  child: const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.link_rounded,
                                                         color: Colors.white,
                                                      ),
                                                      SizedBox(width: 15),
                                                      Text(
                                                        'Go to site',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                const Text(
                                                  'This app does not track or transmit any data to any server. All calculations are processed locally on your device, without requiring an internet connection. Additionally, it is completely free and ad-free, ensuring a seamless experience while safeguarding your privacy.',
                                                  textAlign: TextAlign.justify,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                                const SizedBox(height: 15),
                                                const Text(
                                                  'Rights Reserved: Cafi © 2025',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    HapticFeedback.mediumImpact();
                                                    launchUrl(Uri.parse('mailto:business@cafi.one?subject="MA Calculator mini app contact"'));
                                                  },
                                                  child: const Text(
                                                    'Email: business@cafi.one',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w400,
                                                    ),
                                                  ),
                                                ),
                                                const Text(
                                                  'Lead developer: Carlos Madrigal',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  icon: const Icon(Icons.info_outline_rounded),
                                ),
                              ),
                              Tooltip(
                                message: 'Switch Theme',
                                child: IconButton(
                                  splashRadius: 20.0,
                                  onPressed: _setTheme,
                                  icon: Icon(themeIcon),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tooltip(
                          message: 'Delete',
                          child: IconButton(
                            splashRadius: 20.0,
                            disabledColor: Theme.of(context).disabledColor.withOpacity(0.4),
                            onPressed: isInitial
                                ? null
                                : () =>
                                    context.read<CalculationCubit>().onDelete(),
                            icon: const Icon(Icons.backspace_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(thickness: 1),
                  Container(
                    constraints: const BoxConstraints(
                      maxWidth: 700,
                    ),
                    child: Stack(
                      children: [
                        GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16.0),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 8.0,
                            crossAxisSpacing: 16.0,
                          ),
                          children: buttons
                              .map((e) => _ButtonItem(buttonModel: e))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ButtonItem extends StatefulWidget {
  const _ButtonItem({
    Key? key,
    required this.buttonModel,
  }) : super(key: key);

  final ButtonModel buttonModel;

  @override
  State<_ButtonItem> createState() => __ButtonItemState();
}

class __ButtonItemState extends State<_ButtonItem> {
  String? _longPress;

  @override
  Widget build(BuildContext context) {
    final operator = widget.buttonModel.operator;
    final isHold = _longPress == operator;
    final tooltip = widget.buttonModel.tooltip ?? '';
    final isParentheses = operator == '()';
    final isDelete = operator == '⌫';
    final isClear = operator == 'C';
    final isEqual = operator == '=';
    final color = isEqual ? Colors.white : isClear ? Colors.red : Theme.of(context).textTheme.bodyMedium?.color;
    final backgroundColor = isEqual ? const Color.fromARGB(255, 39, 45, 54) : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.1);
    final size = widget.buttonModel.size;
    final isBold = widget.buttonModel.isBold;

    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(100),
            onTapUp: (details) {
              if (mounted) {
                setState(() {
                  _longPress = null;
                });
              }
            },
            onTapDown: (details) {
              HapticFeedback.mediumImpact();
              if (mounted) {
                setState(() {
                  _longPress = operator;
                });
              }
            },
            onTapCancel: () {
              if (mounted) {
                setState(() {
                  _longPress = null;
                });
              }
            },
            onTap: () async {
              HapticFeedback.mediumImpact();
              if (mounted) {
                setState(() {
                  _longPress = operator;
                });
              }
              if (isDelete) {
                context.read<CalculationCubit>().onDelete();
              } else if (isClear) {
                context.read<CalculationCubit>().onClear();
              } else if (isEqual) {
                context.read<CalculationCubit>().onEqual();
              } else {
                context.read<CalculationCubit>().onAdd(operator);
              }
              await Future.delayed(const Duration(milliseconds: 100));
              if (mounted) {
                setState(() {
                  _longPress = null;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: FittedBox(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 100),
                    style: TextStyle(
                      color: color,
                      fontSize: size - (isHold ? 5 : 0),
                      letterSpacing: isParentheses ? 8 : null,
                      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    ),
                    child: Text(operator),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
