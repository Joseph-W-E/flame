import 'dart:ui';
import 'dart:typed_data';

import 'package:meta/meta.dart';

abstract class Game {
  // these are all the previously held callbacks from the Flutter engine
  // this is probably a poor solution to injecting our own rendering stuff
  FrameCallback _previousOnBeginFrame;
  VoidCallback _previousOnDrawFrame;
  PointerDataPacketCallback _previousOnPointerDataPacket;

  // the previous time (game clock)
  Duration _previous = Duration.ZERO;

  /// Called when the game is updating.
  ///   [t] is the time since the previous update.
  void update(double t);

  /// Called when the game is rendering.
  ///   [canvas] is what you will render your components on.
  void render(Canvas canvas);

  /// Starts the game by injecting render callbacks into the Flutter engine.
  void start({@required PointerDataPacketCallback onInput}) {
    _previousOnBeginFrame = window.onBeginFrame;
    _previousOnDrawFrame = window.onDrawFrame;
    _previousOnPointerDataPacket = window.onPointerDataPacket;

    window.onBeginFrame = _onBeginFrame;
    window.onDrawFrame = _onDrawFrame;
    window.onPointerDataPacket = onInput;

    window.scheduleFrame();
  }

  /// Stops the game by replacing the injected render callbacks with
  /// the original Flutter callbacks.
  void stop() {
    window.onBeginFrame = _previousOnBeginFrame;
    window.onDrawFrame = _previousOnDrawFrame;
    window.onPointerDataPacket = _previousOnPointerDataPacket;
  }

  void _onBeginFrame(Duration now) {
    var recorder = new PictureRecorder();
    var canvas = new Canvas(
      recorder,
      new Rect.fromLTWH(0.0, 0.0, window.physicalSize.width, window.physicalSize.height),
    );

    Duration delta = now - _previous;
    if (_previous == Duration.ZERO) {
      delta = Duration.ZERO;
    }
    _previous = now;

    var t = delta.inMicroseconds / Duration.MICROSECONDS_PER_SECOND;

    update(t);
    render(canvas);

    var deviceTransform = new Float64List(16)
      ..[0] = 1.0 // window.devicePixelRatio
      ..[5] = 1.0 // window.devicePixelRatio
      ..[10] = 1.0
      ..[15] = 1.0;

    var builder = new SceneBuilder()
      ..pushTransform(deviceTransform)
      ..addPicture(Offset.zero, recorder.endRecording())
      ..pop();

    window.render(builder.build());
  }

  void _onDrawFrame() => window.scheduleFrame();
}