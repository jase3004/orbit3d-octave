% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% This Source Code Form is subject to the terms of the Mozilla Public   %
% License, v. 2.0. If a copy of the MPL was not distributed with this   %
% file, You can obtain one at http://mozilla.org/MPL/2.0/.              %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

%units are Meters and Seconds
%uses Octave plot autoscaling to make it possible to see everything

%set up coordinate system and other constants

timestep = 20
duration = 15*60*60
G = 6.674e-11
M = 5.9736e24
earthR = 6.36e6
x0sat = 0
y0sat = earthR
z0sat = 0

xVel0sat = 0
yVel0sat = 10*timestep
zVel0sat = 0

deltavee = [
  0*30,         0,    1500, 0;
  1*30,         0,    1500, 0;
  2*30,         1000, 0,    1500;
  3*30,         1000, 0,    1500;
  4*30,         1000, 0,    1500;
  5*30,         1000, 0,    0;
  6*30,         1200, 0,    0;
  7*30,         1200, 0,    0;
  8*30,         1000, 0,    0;
  9*30,         1000, 0,    0;
  45*60,        -50,  0,    0;
  12.25*60*60,  -100, -100, 0;
  ] %[second-to-do-burn, x-deltavee, y-deltavee, z-deltavee]

sortrows(deltavee, 1); %get the planned burns in chronological order
deltavee = [deltavee; duration+1, 0, 0, 0] ; %add a stopgap burn right at the end to prevent a crash in the simuulation

%draw earth by plotting points in vectors

[x, y, z] = sphere(40);
surf(x * earthR, y * earthR, z * earthR)
hold on
axis equal

%calculate and draw orbit by plotting points in vectors

%Start at x0sat and y0sat, using initial velocity calculate next [x,y] and add 
% to array.  Also calculate the new [x,y] pair's velocity and acceleration, 
% then repeat for the next timestep
x = x0sat;
y = y0sat;
z = z0sat;

X = [x];
Y = [y];
Z = [z];

xVel = xVel0sat;
yVel = yVel0sat;
zVel = zVel0sat;

r = sqrt(x0sat**2 + y0sat**2 + z0sat**2); %satellite distance from earth center
deorbit=false;

maxVel = sqrt(xVel**2 + yVel**2 + zVel**2);
apR = 0;
peR = inf;

for t = 0:timestep:duration
  xAccel = -((G * M) / r**3) * x;
  yAccel = -((G * M) / r**3) * y;
  zAccel = -((G * M) / r**3) * z;
  
  xVel = xVel + xAccel * timestep; 
  yVel = yVel + yAccel * timestep;
  zVel = zVel + zAccel * timestep;
  
  curVel = sqrt(xVel**2 + yVel**2 + zVel**2);
  if (curVel > maxVel)
    maxVel = curVel;
    maxVelTime = t;
  endif
  
  %apply burn plan
  if (t > deltavee(1,1))
    xVel = xVel + deltavee(1, 2);
    yVel = yVel + deltavee(1, 3);
    zVel = zVel + deltavee(1, 4);
    
    %brag about the burn that just happened
    disp(["Just burned: ", mat2str(deltavee(1, :))])
    plot3(x, y, z, " dr")
    
    deltavee(1,:) = [] ; %hey look, it's a stack of burn plans!  Zap the top one
    peR = inf;
  endif
  
  %apply atmospheric drag
  if (r < earthR + 400e3)
    if (r > earthR + 1)
      alt = r - earthR;
      xVel = xVel - (xVel / alt) * timestep;
      yVel = yVel - (yVel / alt) * timestep;
      zVel = zVel - (zVel / alt) * timestep;
    endif
  endif
  
  x = x + xVel * timestep;
  y = y + yVel * timestep;
  z = z + zVel * timestep;
  
  r = sqrt(x**2 + y**2 + z**2); %update satellite distance from earth center
  
  if (r > apR)
    apR = r;
    apT = t;
  endif
  if (r < peR)
    peR = r;
    peT = t;
  endif
  if (r < earthR)
    deorbit=true;
    plot3(x, y, z, " xr")
    disp(["Deorbit at (t, x, y, z): ", mat2str([t, x, y, z])])
    break; %exit simulation loop
  endif
  
  %build up X, Y, Z vectors for later 3d plotting
  X = [X, x];
  Y = [Y, y];
  Z = [Z, z];
  
endfor

plot3(X, Y, Z);

apAlt = apR - earthR;
peAlt = peR - earthR;

endVelocity = sqrt(xVel**2 + yVel**2 + zVel**2);
disp ("")
disp ("End of simulation variables:")
t
endVelocity
maxVel
maxVelTime
apR
apAlt
apT
peR %pe is calculated AFTER last burn
peAlt 
peT
deorbit

for t = 0:1:1000
  usleep(1e4)
  view(-37.5+t, 30+t/3)
endfor
