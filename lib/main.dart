import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Model
class Quote {
  final String id;
  final String text;
  final String author;
  Quote({required this.id, required this.text, required this.author});
}

// Events
abstract class QuoteEvent {}
class LoadQuotes extends QuoteEvent {}
class AddQuote extends QuoteEvent {
  final String text, author;
  AddQuote({required this.text, required this.author});
}
class DeleteQuote extends QuoteEvent {
  final String id;
  DeleteQuote(this.id);
}

// States
abstract class QuoteState {}
class QuoteInitial extends QuoteState {}
class QuoteLoading extends QuoteState {}
class QuoteLoaded extends QuoteState {
  final List<Quote> quotes;
  QuoteLoaded(this.quotes);
}
class QuoteError extends QuoteState {
  final String message;
  QuoteError(this.message);
}

// BLoC
class QuoteBloc extends Bloc<QuoteEvent, QuoteState> {
  List<Quote> _quotes = [
    Quote(id: '1', text: 'Be the change you wish to see in the world', author: 'Mahatma Gandhi'),
    Quote(id: '2', text: 'Stay hungry, stay foolish', author: 'Steve Jobs'),
    Quote(id: '3', text: 'The only limit is your mind', author: 'Anonymous'),
  ];

  QuoteBloc() : super(QuoteInitial()) {
    on<LoadQuotes>((event, emit) async {
      emit(QuoteLoading());
      await Future.delayed(Duration(milliseconds: 500));
      emit(QuoteLoaded(_quotes));
    });
    
    on<AddQuote>((event, emit) async {
      final newQuote = Quote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: event.text,
        author: event.author,
      );
      _quotes.insert(0, newQuote);
      emit(QuoteLoaded(_quotes));
    });
    
    on<DeleteQuote>((event, emit) async {
      _quotes.removeWhere((q) => q.id == event.id);
      emit(QuoteLoaded(_quotes));
    });
  }
}

// Home Screen
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quote Keeper'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<QuoteBloc, QuoteState>(
        builder: (context, state) {
          if (state is QuoteLoading) {
            return Center(child: CircularProgressIndicator());
          }
          if (state is QuoteLoaded) {
            if (state.quotes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.format_quote, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No quotes yet!'),
                    SizedBox(height: 8),
                    Text('Tap + to add your first quote'),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: state.quotes.length,
              itemBuilder: (context, index) {
                final quote = state.quotes[index];
                return Card(
                  elevation: 3,
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('${index + 1}'),
                      backgroundColor: Colors.indigo,
                    ),
                    title: Text(
                      quote.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('- ${quote.author}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        context.read<QuoteBloc>().add(DeleteQuote(quote.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Quote deleted'), backgroundColor: Colors.red),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          }
          if (state is QuoteError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return Center(child: Text('Tap + to add a quote'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final textController = TextEditingController();
    final authorController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Quote'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'Enter your quote',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 12),
            TextField(
              controller: authorController,
              decoration: InputDecoration(
                hintText: 'Author name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty && authorController.text.isNotEmpty) {
                context.read<QuoteBloc>().add(
                  AddQuote(text: textController.text, author: authorController.text),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Quote added!'), backgroundColor: Colors.green),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}

// Main App
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quote Keeper',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (context) => QuoteBloc()..add(LoadQuotes()),
        child: HomeScreen(),
      ),
    );
  }
}