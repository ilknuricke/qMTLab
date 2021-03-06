function [dM, out2, out3] = thermal_2pool(p, t, M, flag, sequence, T1, T2, Ka, F, dw)
%
%  function dM = thermal_2pool_flex(t, M, flag, sequence, T1, T2, Ka, ...
%                                   F, dw, line)
%
%  ODE file implementing equations of motion for two exchanging pools,
%  one governed by the Bloch equations the other by a thermal model
%  with a user specified lineshape.
%
%  p          : model object
%  t          : time in seconds
%  M          : column vector with six magnetization components
%               [MxA MyA MzA MxB MyB MzB]'
%  sequence   : sequence file such that sequence(t) = gamma*B1(t)
%  T1         : [T1A T1B]   longitudinal relaxation in absence of exchange
%  T2         : [T2A T2B]   transverse relaxation
%  Ka         : exchange rate for A -> B
%  F          : ratio of  Mb / Ma
%  dw         : offset frequency of rotating frame = w - w0

if nargin < 3 | isempty(flag)

  if(isa(sequence, 'double'))
    w1 = 0;
  else
    w1 = exp(sqrt(-1)*t*dw)*omega1(sequence,t);
  end
  w1x = real(w1);
  w1y = imag(w1);
  Kb = Ka/F;
  dM = zeros(4,size(M,2));

  MxA = M(1,:);
  MyA = M(2,:);
  MzA = M(3,:);
  MzB = M(4,:);

  dM(1,:) = -MxA/T2(1) - dw*MyA - w1y*MzA;
  dM(2,:) = -MyA/T2(1) + dw*MxA + w1x*MzA;
  dM(3,:) = (1 - MzA)/T1(1) - Ka*MzA + Kb*MzB + w1y*MxA - w1x*MyA;
  if(isa(sequence, 'double'))
    dM(4,:) = (F - MzB)/T1(2) - Kb*MzB + Ka*MzA;
  else
    dM(4,:) = (F - MzB)/T1(2) - Kb*MzB + Ka*MzA - ...
        pi*abs(w1)^2*lineshape(p.lineshape, T2(2), offset(sequence))*MzB;
  end
  
else
  switch(flag)
    case 'init'                           % Return default [tspan,y0,options].
      dM = [0 1];
      out2 = [0 0 1 1];
      out3 = [];
    case 'jacobian'
      if(isa(sequence, 'double'))
        w1 = 0;
      else
        w1 = exp(sqrt(-1)*t*dw)*omega1(sequence,t);
      end
      w1x = real(w1);
      w1y = imag(w1);
      dM = zeros(4,4);
      Kb = Ka/F;
      
      dM(1,:) = [-1/T2(1) -dw    -w1y              0  ];
      dM(2,:) = [  dw    -1/T2(1)  w1x             0  ]; 
      dM(3,:) = [ w1y     -w1x   -Ka-1/T1(1)       Kb  ];
      if(isa(sequence, 'double'))
        dM(4,:) = [  0        0      Ka         -1/T1(2)-Kb];
      else
        dM(4,:) = [  0        0      Ka         -1/T1(2)-Kb-pi*abs(w1)^2*lineshape(p.lineshape, T2(2), offset(sequence))];
      end
    otherwise
      error(['Unknown flag ''' flag '''.']);
  end
end

