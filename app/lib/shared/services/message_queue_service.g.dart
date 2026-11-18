// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_queue_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(messageQueueService)
final messageQueueServiceProvider = MessageQueueServiceProvider._();

final class MessageQueueServiceProvider
    extends
        $FunctionalProvider<
          MessageQueueService,
          MessageQueueService,
          MessageQueueService
        >
    with $Provider<MessageQueueService> {
  MessageQueueServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageQueueServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageQueueServiceHash();

  @$internal
  @override
  $ProviderElement<MessageQueueService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MessageQueueService create(Ref ref) {
    return messageQueueService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageQueueService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessageQueueService>(value),
    );
  }
}

String _$messageQueueServiceHash() =>
    r'3fbb68bd0fac6240652f63cc13cbbaa0b30ca9d8';

@ProviderFor(pendingMessageCount)
final pendingMessageCountProvider = PendingMessageCountProvider._();

final class PendingMessageCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  PendingMessageCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingMessageCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingMessageCountHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return pendingMessageCount(ref);
  }
}

String _$pendingMessageCountHash() =>
    r'ad6641b7ebfb491036ea30a2dbde6ea00a30c9a7';
