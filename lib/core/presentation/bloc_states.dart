enum LoadStatus { initial, loading, success, failure }

class LoadState<T> {
  const LoadState({this.status = LoadStatus.initial, this.value, this.error});

  const LoadState.loading() : this(status: LoadStatus.loading);
  const LoadState.success(T value)
    : this(status: LoadStatus.success, value: value);
  const LoadState.failure(Object error)
    : this(status: LoadStatus.failure, error: error);

  final LoadStatus status;
  final T? value;
  final Object? error;

  bool get isLoading => status == LoadStatus.loading;
  bool get hasError => status == LoadStatus.failure;
}
