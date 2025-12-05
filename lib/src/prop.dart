import 'dart:async';

import 'package:flutter/foundation.dart';

///The base class for any prop, extend this to make your own custom prop.
abstract class PropBase<T> extends ChangeNotifier {
  /// Whether the prop's value is currently valid and ready to be used.
  bool get valid;

  /// Whether the prop contains an error.
  bool get hasError;

  /// The current value of the prop, which may be stale or null.
  T? get value;

  /// The error object, if any.
  Object? get error;

  /// The stack trace for the error, if any.
  StackTrace? get stackTrace;

  /// Requires the value of the prop, throwing an exception if it's not valid.
  T get require;

  /// Manually marks the prop as invalid.
  void invalidate();

  /// Manually marks the prop as valid, if it doesn't currently have an error.
  void validate();
}

/// A [Prop] is a property that can hold a value, an error, or be in a loading state.
///
/// It is designed to facilitate safe handling of values that are fetched asynchronously
/// or can result from operations that might fail.
class Prop<T> extends PropBase<T> {
  T? _value;
  Object? _error;
  StackTrace? _stackTrace;

  bool _isLoading = false;
  bool _isValid;

  /// Creates a [Prop] with an initial value, marked as valid.
  Prop.withValue(T value) : _value = value, _isValid = true;

  /// Creates an empty [Prop], marked as invalid.
  Prop.empty() : _isValid = false;

  /// The current value of the prop.
  /// This can be accessed even when the prop is not [valid], for example to show a stale value.
  @override
  T? get value => _value;

  /// The error object, if the last operation failed.
  @override
  Object? get error => _error;

  /// The stack trace for the error, if available.
  @override
  StackTrace? get stackTrace => _stackTrace;

  /// Whether the prop is currently executing an asynchronous operation.
  bool get isLoading => _isLoading;

  @override
  bool get valid => _isValid && !hasError && !_isLoading;

  @override
  bool get hasError => _error != null;

  @override
  T get require {
    if (valid) {
      return _value as T;
    }
    if (_isLoading) {
      throw StateError('Cannot require value: Prop is loading.');
    }
    if (hasError) {
      throw StateError('Cannot require value: Prop has an error: $_error');
    }
    throw StateError('Cannot require value: Prop is invalid.');
  }

  /// Sets a new [value] for the prop and marks it as valid.
  /// This will clear any existing error.
  void set(T value) {
    _value = value;
    _isValid = true;
    _error = null;
    _stackTrace = null;
    notifyListeners();
  }

  /// Executes an asynchronous [operation] and updates the prop with its outcome.
  ///
  /// While the operation is running, [isLoading] is true and the prop is not [valid].
  /// On success, the prop's value is updated.
  /// On failure, the prop will hold the error and be marked as invalid.
  Future<void> run(
    Future<T> Function() operation, {
    void Function(T value)? onSucces,
    void Function(Object error, StackTrace st)? onFailure,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final value = await operation();
      onSucces?.call(value);
      set(value);
    } catch (e, s) {
      _error = e;
      _stackTrace = s;
      _isValid = false;
      onFailure?.call(e, s);
    } finally {
      _isLoading = false;
      // Also notify here to signal that loading is finished.
      notifyListeners();
    }
  }

  /// Executes a synchronous [operation] and updates the prop with its outcome.
  ///
  /// On success, the prop's value is updated.
  /// On failure, the prop will hold the error and be marked as invalid.
  void runSync(
    T Function() operation, {
    void Function(T value)? onSucces,
    void Function(Object error, StackTrace st)? onFailure,
  }) {
    try {
      final value = operation();
      onSucces?.call(value);
      set(value);
    } catch (e, s) {
      _error = e;
      _stackTrace = s;
      _isValid = false;
      onFailure?.call(e, s);
      notifyListeners();
    }
  }

  /// Executes an asynchronous [operation] using the prop's current value as input.
  ///
  /// If the prop is not [valid], this method does nothing.
  /// Otherwise, it passes the current value to the [operation] and updates the
  /// prop with the result, putting it in a loading state while the operation runs.
  Future<void> transform(
    Future<T> Function(T currentValue) operation, {
    void Function(T value)? onSucces,
    void Function(Object error, StackTrace st)? onFailure,
  }) async {
    if (!valid) return;
    final currentValue = _value as T;

    _isLoading = true;
    notifyListeners();
    try {
      final value = await operation(currentValue);
      onSucces?.call(value);
      set(value);
    } catch (e, s) {
      _error = e;
      _stackTrace = s;
      _isValid = false;
      onFailure?.call(e, s);
    } finally {
      _isLoading = false;
      // Also notify here to signal that loading is finished.
      notifyListeners();
    }
  }

  /// Executes a synchronous [operation] using the prop's current value as input.
  ///
  /// If the prop is not [valid], this method does nothing.
  /// Otherwise, it passes the current value to the [operation] and updates the
  /// prop with the result.
  void transformSync(
    T Function(T currentValue) operation, {
    void Function(T value)? onSucces,
    void Function(Object error, StackTrace st)? onFailure,
  }) {
    if (!valid) return;
    final currentValue = _value as T;

    try {
      final value = operation(currentValue);
      onSucces?.call(value);
      set(value);
    } catch (e, s) {
      _error = e;
      _stackTrace = s;
      _isValid = false;
      onFailure?.call(e, s);
      notifyListeners();
    }
  }

  /// Resets the prop to its initial empty state, clearing any value or error.
  void reset() {
    _value = null;
    _error = null;
    _stackTrace = null;
    _isLoading = false;
    _isValid = false;
    notifyListeners();
  }

  @override
  void invalidate() {
    _isValid = false;
    notifyListeners();
  }

  @override
  void validate() {
    if (!hasError) {
      _isValid = true;
      notifyListeners();
    }
  }
}

/// A [SyncProp] is a simplified synchronous property wrapper.
///
/// It holds a value and a validity flag, but does not handle errors or loading states.
/// An initial value is required upon creation.
class SyncProp<T> extends PropBase<T> {
  T _value;
  bool _isValid;

  /// Creates a [SyncProp] with an initial value.
  ///
  /// The [initialValue] is required (unless [T] is nullable) and the prop
  /// starts as valid.
  SyncProp(T initialValue) : _value = initialValue, _isValid = true;

  @override
  bool get valid => _isValid;

  @override
  bool get hasError => false;

  @override
  Object? get error => null;

  @override
  StackTrace? get stackTrace => null;

  @override
  T get require {
    if (!valid) {
      throw StateError('Cannot require value from an invalid SyncProp.');
    }
    return _value;
  }

  /// The current value of the prop.
  @override
  T get value => _value;

  /// Sets a new [newValue] for the prop and marks it as valid.
  void set(T newValue) {
    _value = newValue;
    _isValid = true;
    notifyListeners();
  }

  /// Executes a synchronous [operation] using the prop's current value as input.
  ///
  /// If the prop is not [valid], this method does nothing.
  /// Otherwise, it passes the current value to the [operation] and updates the
  /// prop with the result.
  void transform(
    T Function(T currentValue) operation,
  ) {
    if (!valid) return;
    final currentValue = _value;

    final newValue = operation(currentValue);
    set(newValue);
  }

  @override
  void invalidate() {
    _isValid = false;
    notifyListeners();
  }

  @override
  void validate() {
    if (!hasError) {
      _isValid = true;
      notifyListeners();
    }
  }
}

/// A [StreamProp] is a property that is driven by a [Stream].
///
/// It "hooks" (subscribes) to a stream and updates its value based on the data,
/// error, and done events from that stream.
class StreamProp<T> extends PropBase<T> {
  StreamSubscription<T>? _subscription;
  T? _value;
  Object? _error;
  StackTrace? _stackTrace;
  bool _isValid = false;
  bool _isCompleted = false;

  /// Creates a [StreamProp], optionally hooking to an initial [stream].
  StreamProp([Stream<T>? stream]) {
    if (stream != null) {
      hook(stream);
    }
  }

  /// The latest value emitted by the stream. Can be accessed even when invalid.
  @override
  T? get value => _value;

  /// The error from the stream, if any.
  @override
  Object? get error => _error;

  /// The stack trace for the error, if any.
  @override
  StackTrace? get stackTrace => _stackTrace;

  /// Whether the stream has completed.
  bool get isCompleted => _isCompleted;

  /// Whether the prop is currently subscribed to a stream.
  bool get isHooked => _subscription != null;

  @override
  bool get hasError => _error != null;

  @override
  bool get valid => _isValid && !hasError;

  @override
  T get require {
    if (valid) {
      return _value as T;
    }
    if (hasError) {
      throw StateError(
        'Cannot require value: StreamProp has an error: $_error',
      );
    }
    throw StateError('Cannot require value: StreamProp is not valid.');
  }

  /// Subscribes to a [stream] to receive updates.
  ///
  /// If already hooked to a stream, it will be unhooked first. The prop's state
  /// (error, completion) is reset when hooking to a new stream.
  void hook(Stream<T> stream) {
    unhook();
    _isCompleted = false;
    _error = null;
    _stackTrace = null;
    notifyListeners(); // Notify that we are about to listen to a new stream

    _subscription = stream.listen(
      (data) {
        _value = data;
        _isValid = true;
        _error = null;
        _stackTrace = null;
        notifyListeners();
      },
      onError: (error, stackTrace) {
        _error = error;
        _stackTrace = stackTrace;
        _isValid = false;
        notifyListeners();
      },
      onDone: () {
        _isCompleted = true;
        _subscription = null;
        notifyListeners();
      },
    );
  }

  /// Cancels the subscription to the current stream.
  ///
  /// The last received value is preserved.
  void unhook() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    unhook();
    super.dispose();
  }

  @override
  void invalidate() {
    _isValid = false;
    notifyListeners();
  }

  @override
  void validate() {
    if (!hasError) {
      _isValid = true;
      notifyListeners();
    }
  }
}

/// A declarative version of [Prop] that is driven by a [Future].
///
/// Simply construct it with a future, and it will automatically manage the
/// loading, error, and valid states.
class FutureProp<T> extends Prop<T> {
  /// Creates a [FutureProp] and immediately starts executing the [future].
  FutureProp(Future<T> future) : super.empty() {
    run(() => future);
  }

  /// Re-runs the prop with a new [future].
  void refresh(Future<T> future) {
    run(() => future);
  }
}

/// A specialized [Prop] that debounces operations.
///
/// This is useful for scenarios like live search fields, where you want to
/// delay an operation until the user has stopped typing for a certain duration.
class DebouncedProp<T> extends Prop<T> {
  Timer? _debounce;
  final Duration debounceDuration;

  /// Creates a [DebouncedProp].
  ///
  /// [debounceDuration] defaults to 300 milliseconds.
  DebouncedProp({
    T? initialValue,
    this.debounceDuration = const Duration(milliseconds: 300),
  }) : super.empty() {
    if (initialValue != null) {
      set(initialValue);
    }
  }

  /// Executes the given [operation] after the [debounceDuration] has passed
  /// without any new calls to `debounce`.
  void debounce(Future<T> Function() operation) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }
    _debounce = Timer(debounceDuration, () {
      run(operation);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

/// A specialized [Prop] for managing paginated data, where one page of
/// content is viewed at a time. This is suitable for traditional paginators.
class PaginatedProp<T> extends Prop<List<T>> {
  int _currentPage;

  final int _initialPage;

  Future<List<T>> Function(int page) _fetcher;

  /// The page number of the currently visible page.
  int get currentPage => _currentPage;

  /// Creates a [PaginatedProp].
  ///
  /// The prop starts in an empty state. You must call [fetchInitialPage] or
  /// [fetchPage] to load the first page of data.
  /// The [fetcher] function is required to load pages.
  /// [initialPage] can be set to 1 or 0 depending on the API's pagination scheme.
  PaginatedProp(this._fetcher, {int initialPage = 1})
    : _currentPage = initialPage,
      _initialPage = initialPage,
      super.empty();

  /// Replaces the current fetcher function with a [newFetcher].
  void setFetcher(Future<List<T>> Function(int page) newFetcher) {
    _fetcher = newFetcher;
  }

  /// Fetches the initial page of data.
  Future<void> fetchInitialPage() async {
    await fetchPage(_initialPage);
  }

  /// Fetches the next page of data and replaces the current content.
  Future<void> fetchNextPage() async {
    await fetchPage(_currentPage + 1);
  }

  /// Fetches the previous page of data and replaces the current content.
  ///
  /// Does nothing if the current page is the initial page.
  Future<void> fetchPreviousPage() async {
    if (_currentPage > _initialPage) {
      await fetchPage(_currentPage - 1);
    }
  }

  /// Fetches a specific [pageNumber] and replaces the current value of the prop with the result.
  ///
  /// This puts the entire prop into a loading state via the `run` method.
  /// On success, the internal page counter is updated to [pageNumber].
  Future<void> fetchPage(int pageNumber) async {
    if (pageNumber < _initialPage) return;

    await run(() => _fetcher(pageNumber));
    // If the fetch was successful, update the page counter.
    if (!hasError) {
      _currentPage = pageNumber;
    }
  }

  /// Resets the prop to its initial empty state and resets the page count.
  @override
  void reset() {
    super.reset();
    _currentPage = _initialPage;
  }
}
