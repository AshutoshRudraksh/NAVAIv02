class TimerUtil {
  late DateTime _startTime;
  late DateTime _endTime;

  void startTimer() {
    _startTime = DateTime.now();
    // print("Timer started at: $_startTime");
  }

  void stopTimer(String function) {
    _endTime = DateTime.now();
    Duration duration = _endTime.difference(_startTime);
    // print("Timer stopped at: $_endTime");
    print(
        "Total time taken for ${function}: ${duration.inMilliseconds} milliSeconds");
  }
}
