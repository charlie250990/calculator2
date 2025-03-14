part of 'calculation_cubit.dart';

class CalculationState extends Equatable {
  final String question;
  final num? answer;
  final bool isError;
  final String? error;
  final int? cursorPosition;

  const CalculationState({
    this.question = '0',
    this.answer,
    this.isError = false,
    this.error,
    this.cursorPosition,
  });

  List<String> get questionSplit => question.split('').toList();
  bool get isInitial => question == '0';
  bool get increase1 => questionSplit.length > 13;
  bool get increase2 => questionSplit.length > 19;

  CalculationState copyWith({
    String? question,
    num? answer,
    bool? isError,
    String? error,
    int? cursorPosition,
  }) {
    return CalculationState(
      question: question ?? this.question,
      answer: answer ?? this.answer,
      isError: isError ?? this.isError,
      error: error ?? this.error,
      cursorPosition: cursorPosition ?? this.cursorPosition,
    );
  }

  @override
  List<Object?> get props => [question, answer, isError, error, cursorPosition];
}
