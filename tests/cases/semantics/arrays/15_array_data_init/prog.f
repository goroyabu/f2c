      PROGRAM ARDATA
      INTEGER A(3)
      DATA A /4, 5, 6/
      WRITE (*, 100) A(1), A(2), A(3)
  100 FORMAT (I1, 1X, I1, 1X, I1)
      END
