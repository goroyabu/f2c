      PROGRAM SUM1TO5
      INTEGER N, I, S
      PARAMETER (N=5)
      S = 0
      DO 10 I = 1, N
        S = S + I
10    CONTINUE
      PRINT *, S
      STOP
      END
