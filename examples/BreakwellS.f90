!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
! File BreakwellS.f90
!
!  The problem in Bolza form:
!      min            (1/2) * integral{0, 1}  u^2
!      subject to:
!                     y1' = y2
!                     y2' = u
!                     y1(0) = 0
!                     y2(0) = 1
!
!                     y1(1) = 0
!                     y2(1) = -1
!
!                     y1 <= 0.1
!
!  The problem input to SNCTRL:
!        min          y1(1)
!        subject to:
!                     y1' = (1/2)*u^2
!                     y2' = y3
!                     y3' = u
!
!                     y1(0) = 0
!                     y2(0) = 0
!                     y3(0) = 1
!
!                     y2(1) = 0
!                     y3(1) = -1
!
!                     y2 <= 0.1
!
!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

program BreakwellS
  use SNCTRL
  implicit none

  !=====================================================================

  ! SNOPT variables and workspaces
  character(20) :: lfile
  real(rp)      :: sInf
  integer(ip)   :: Start, INFO, iPrint, iSpecs, nOut, &
                   iSumm, mincw, miniw, minrw, nS, nInf, &
                   lencu, leniu, lenru, &
                   lencw, leniw, lenrw
  parameter ( lenrw = 50000, leniw = 50000, lencw = 500, &
              lenru = 1,     leniu = 1,     lencu = 1)
  integer(ip)  :: iu(leniu), iw(leniw)
  real(rp)     :: ru(lenru), rw(lenrw)
  character(8) :: cu(lencu), cw(lencw)

  external     :: odecon, algcon, varbds
  type(ctProb) :: prob

  !=====================================================================

  iSpecs =  4  ! equivalenced to .spc
  iPrint =  9  ! equivalenced to .out
  iSumm  =  6  ! summary file goes to standard output...
  nOut   =  6  ! ... as do messages from this program.

  ! Open the Specs and print files.
  lfile = 'BreakwellS.spc'
  open( iSpecs, file=lfile, status='OLD',     err=800 )
  lfile = 'BreakwellS.out'
  open( iPrint, file=lfile, status='UNKNOWN', err=800 )


  ! Set options to default values.
  call sncInit( iPrint, iSumm, prob, cw, lencw, iw, leniw, rw, lenrw )


  ! Read a Specs file.
  call sncSpec( iSpecs, INFO, cw, lencw, iw, leniw, rw, lenrw )

  if (INFO /= 101  .AND.  INFO /= 107) go to 910


  ! Setup the problem.
  prob%probname = 'BrkwellS'
  prob%nY   = 3     ! number of states
  prob%nU   = 1     ! number of controls
  prob%nP   = 0     ! number of parameters
  prob%nC   = 0     ! number of algebraic constraints
  prob%nPhs = 1     ! number of phases

  ! Objective
  allocate ( prob%objL(1) )
  prob%objL(1) = 1

  ! Interval
  allocate ( prob%npInt(1), prob%phsPt(2) )
  prob%npInt(1) = 10
  prob%phsPt(1) = 0
  prob%phsPt(2) = 1.0

  ! Linearity
  allocate ( prob%ytype(3,1) )
  prob%ytype(1,1) = 0
  prob%ytype(2,1) = 1
  prob%ytype(3,1) = 1

  ! Derivatives
  allocate ( prob%neJ(1) )
  prob%neJ(1) = 3


   !---------------------------------------------------------------------
  ! Solve the problem.
  !---------------------------------------------------------------------
  Start = 0
  call snctrlS( Start, prob, odecon, algcon, varbds, &
                INFO, mincw, miniw, minrw, nS, nInf, sInf, &
                cu, lencu, iu, leniu, ru, lenru, &
                cw, lencw, iw, leniw, rw, lenrw )

  if (INFO == 82 .OR. INFO == 83 .OR. INFO == 84) then
     go to 910
  end if

  write(nOut, *) ' '
  write(nOut, *) 'snctrl finished.'
  write(nOut, *) 'INFO          =', INFO
  write(nOut, *) 'nInf          =', nInf
  write(nOut, *) 'sInf          =', sInf

  call sncEnd( prob )

  if (INFO >= 30) go to 900

  stop

  !---------------------------------------------------------------------
  ! Error exit.
  !---------------------------------------------------------------------
800 write(nOut, 4000) 'Error while opening file', lfile
  stop

900 write(nOut, *) ' '
  write(nOut, *) 'STOPPING because of error condition'
910 stop

4000 format(/  a, 2x, a  )

end program BreakwellS

!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

subroutine varbds ( curPhs, nPhs, nY, nU, nP, nC, nNodes, lbds, ubds, x, &
                    plbds, pubds, p, clbds, cubds )
  use precision, only : ip, rp
  implicit none
  integer(ip), intent(in)  :: curPhs, nPhs, nY, nU, nP, nC, nNodes
  real(rp),    intent(out) :: lbds(nY+nU,nNodes), ubds(nY+nU,nNodes), &
                              x(nY+nU,nNodes), plbds(nP), pubds(nP), p(nP), &
                              clbds(nC), cubds(nC)
  !=============================================================================
  integer(ip) :: j
  real(rp)    :: bplus, bminus
  parameter    ( bplus  = 1.0d+20, bminus = -bplus )

  ! Default set everything to free bounds and initial point is 0.
  lbds = bminus
  ubds = bplus
  x    = 0.0

  ! At t in (t0, tf)
  do j = 1, nNodes
     ubds(2,:) = 0.1
  end do

  ! At t0
  lbds(1,1) = 0.0
  lbds(2,1) = 0.0
  lbds(3,1) = 1.0
  lbds(4,1) = bminus

  ubds(1,1) = 0.0
  ubds(2,1) = 0.0
  ubds(3,1) = 1.0
  ubds(4,1) = bplus

  ! At tf
  lbds(1,nNodes) = bminus
  lbds(2,nNodes) = 0.0
  lbds(3,nNodes) = -1.0
  lbds(4,nNodes) = bminus

  ubds(1,nNodes) = bplus
  ubds(2,nNodes) = 0.0
  ubds(3,nNodes) = -1.0
  ubds(4,nNodes) = bplus

end subroutine varbds

!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


subroutine odecon ( snStat, curPhs, nPhs, nY, nU, nP, nNodes, F, &
                    Jrow, Jval, Jcol, lenJ, dvar, pvar, needF, needJ, &
                    cu, lencu, iu, leniu, ru, lenru )
  use precision, only : ip, rp
  implicit none
  integer(ip), intent(in) :: snStat, curPhs, nPhs, nY, nU, nP, nNodes, lenJ, &
                             needF, needJ, lencu, leniu, lenru
  real(rp),    intent(in) :: dvar(nY+nU,nNodes), pvar(nP)

  integer(ip), intent(inout) :: iu(leniu)
  real(rp),    intent(inout) :: ru(lenru)
  character(8),intent(inout) :: cu(lencu)

  integer(ip), intent(out) :: Jrow(lenJ), Jcol(nY+nU+nP)
  real(rp),    intent(out) :: F(nY,nNodes), Jval(lenJ,nNodes)

  !=============================================================================
  integer(ip) :: jt, neJ


  ! F(1) = (u(1)**2)/2.0d+0
  ! F(2) = y(3)
  ! F(3) = u(1)

  if (needF > 0) then
     do jt = 1, nNodes
        F(1,jt) = ( dvar(1+nY,jt)**2 ) / 2.0
        F(2,jt) = dvar(3,jt)
        F(3,jt) = dvar(1+nY,jt)
     end do
  end if

  if (needJ > 0) then
     do jt = 1, nNodes
        neJ = 1
        ! Column 1
        Jcol(1) = neJ

        ! Column 2
        Jcol(2) = neJ

        ! Column 3
        Jcol(3) = neJ

        Jrow(neJ) = 2
        Jval(neJ,jt) = 1.0
        neJ = neJ + 1

        ! Column 4
        Jcol(4) = neJ

        Jrow(neJ) = 1
        Jval(neJ,jt) = dvar(1+nY,jt)
        neJ = neJ + 1

        Jrow(neJ) = 3
        Jval(neJ,jt) = 1.0
        neJ = neJ + 1

        ! Finish off column pointers
        Jcol(5) = neJ
        neJ = neJ - 1
     end do
  end if

end subroutine odecon

!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


subroutine algcon ( snStat, curPhs, nPhs, nC, nY, nU, nP, nNodes, C, &
                    Grow, Gval, Gcol, lenG, dvar, pvar, &
                    needC, needG, cu, lencu, iu, leniu, ru, lenru )
  use precision, only : ip, rp
  implicit none
  integer(ip), intent(in) :: snStat, curPhs, nPhs, nC, nY, nU, nP, nNodes, &
                             lenG, needC, needG, lencu, leniu, lenru
  real(rp),    intent(in) :: dvar(nY+nU,nNodes), pvar(nP)

  integer(ip), intent(inout) :: iu(leniu)
  real(rp),    intent(inout) :: ru(lenru)
  character(8),intent(inout) :: cu(lencu)

  integer(ip), intent(out) :: Grow(lenG), Gcol(nY+nU+nP+1)
  real(rp),    intent(out) :: C(nC,nNodes), Gval(lenG,nNodes)

end subroutine algcon

!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
