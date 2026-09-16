      PROGRAM CAS31
      INTEGER IVAL
      REAL RVAL, CVAL
      DOUBLE PRECISION DVAL
      COMPLEX ZVAL
      INTRINSIC ABS
      IVAL = ABS(-7)
      RVAL = ABS(-2.5)
      DVAL = ABS(-4.5D0)
      ZVAL = (3.0, 4.0)
      CVAL = ABS(ZVAL)
      WRITE (*,100) IVAL, RVAL, DVAL, CVAL
  100 FORMAT ('[',I2,'] [',F3.1,'] [',F3.1,'] [',F3.1,']')
      END
