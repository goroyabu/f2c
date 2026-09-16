      PROGRAM LSTCTL
      INTEGER A, B, C, D
      A = 1
      B = 2
      C = 3
      D = 4
      READ (*,*) A, B, C, D
      WRITE (*,100) A, B, C, D
  100 FORMAT (SS,'[',I1,1X,I1,1X,I1,1X,I1,']')
      END
