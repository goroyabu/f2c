      PROGRAM CHRASN
      CHARACTER*5 SHORT, LONG
      SHORT = 'AB'
      LONG = 'ABCDEFG'
      WRITE (*, 100) SHORT, LONG
  100 FORMAT ('[', A5, '] [', A5, ']')
      END
