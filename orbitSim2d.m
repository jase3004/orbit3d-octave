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

xVel0sat = 0
yVel0sat = 10*20
deltavee = [
  0*30, 0, 1500;
  1*30, 0, 1500;
  2*30, 2500, 0;
  3*30, 1500, 0;
  4*30, 1000, 0;
  5*30, 1000, 0;
  6*30, 1000, 0;
  7*30, 1000, 0;
  8*30, 1000, 0;
  9*30, 1000, 0;
  45*60, -50, 0;
  12.25*60*60, -100, -100;
  ] %[second-to-start-burn, x-deltavee, y-deltavee]

sortrows(deltavee, 1); %get the planned burns in chronological order
deltavee = [deltavee; duration*1, 0, 0] ; %add a stopgap burn right at the end to prevent a crash in the simuulation

%draw earth by plotting points in vectors

a = linspace(0, 2*pi, 100);

earthSurfaceX = earthR .* cos(a);
earthSurfaceY = earthR .* sin(a);
%do the actual plot

plot(earthSurfaceX, earthSurfaceY, "  k");
hold on
axis equal


%calculate and draw orbit by plotting points in vectors


%Start at x0sat and y0sat, using initial velocity calculate next [x,y] and add 
% to array.  Also calculate the new [x,y] pair's velocity and acceleration, 
% then repeat for the next timestep
x = x0sat;
y = y0sat;
xVel = xVel0sat;
yVel = yVel0sat;
r = sqrt(x0sat**2 + y0sat**2); %satellite distance from earth center
deorbit=false;

maxVel = sqrt(xVel**2 + yVel**2);
apR = 0;
peR = inf;
for t = 0:timestep:duration
  xAccel = -((G * M) / r**3) * x;
  yAccel = -((G * M) / r**3) * y;
  
  xVel = xVel + xAccel * timestep; 
  yVel = yVel + yAccel * timestep;
  
  curVel = sqrt(xVel**2 + yVel**2);
  if (curVel > maxVel)
    maxVel = curVel;
    maxVelTime = t;
  endif
  
  %apply burn plan
  if (t > deltavee(1,1))
    xVel = xVel + deltavee(1, 2);
    yVel = yVel + deltavee(1, 3);
    
    %brag about the burn that just happened
    disp([mat2str(deltavee(1, :)), " just burned"])
    plot(x, y, " dr")
    
    deltavee(1,:) = [] ; %hey look, it's a stack of burn plans!
    peR = inf;
  endif
  
  %apply atmospheric drag
  if (r < earthR + 400e3)
    if (r > earthR + 1)
      alt = r - earthR;
      xVel = xVel - (xVel / alt) * timestep;
      yVel = yVel - (yVel / alt) * timestep;
    endif
  endif
  
  
  x = x + xVel * timestep;
  y = y + yVel * timestep;
  
  r = sqrt(x**2 + y**2); %update satellite distance from earth center
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
    plot(x, y, " xr")
    break; %exit simulation for loop
  endif
  
  
  plot(x, y, "markersize", 2);
  
  if (mod(t, 100) == 0)
    axis equal
    drawnow()
  endif
  
endfor

apAlt = apR - earthR;
peAlt = peR - earthR;

endVelocity = sqrt(xVel**2 + yVel**2);
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
