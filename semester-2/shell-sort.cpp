void ShellSort(int *a, int n) {
  for (int h = n / 2; h > 0; h /= 2) {
      for (int i = h; i < n; ++i) {
          for (int j = i - h; j >= 0 && a[j] > a[j + h]; j -= h) {
              int temp = a[j];
              a[j] = a[j + h];
              a[j + h] = temp;
          }
      }
  }
}