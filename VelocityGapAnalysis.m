close all;
clear all;
filename = ('Brownian,10,Rolling,Stuck');
v = VideoReader([filename '.m4v']);
global width height fps duration mov frames sizes vel pixperum maxPix aveVel avePix avev stdv startFrame endFrame meanh stdevh shortv;
width = v.Width;
height = v.Height;
fps = v.FrameRate;
duration = v.Duration;
size = 0;
pixperum = 33.5/8.3;
mov = struct('cdata',zeros(height,width,3,'uint8'),'colormap',[]);


frames = 0;
while hasFrame(v)
    vid = readFrame(v);
    frames = frames+1; 
    mov(frames).cdata = vid;
end

startFrame = 2846;
endFrame = 3054;
maxPix = zeros(frames,1);
avePix = zeros(frames,[]);
sizes = zeros(frames,[]);

fig = figure;
[pix, map] = frame2im(mov(1));
thresh = 0.22;
grayPix = rgb2gray(pix);

plotFrame(grayPix,thresh,grayPix);

function plotFrame(pic,thresh,orig)
    imshow(pic);
    threshSlide = uicontrol('Style','slider','Min',0,'Max',256,'Value',thresh,'Position',[400 20 120 20],'Callback',{@replot,pic,orig},'SliderStep',[0.01/256,0.1/256]);
    confirm = uicontrol('Style','pushbutton','String','Confirm','Position',[20 20 50 20],'Callback',{@measureVelocity,thresh});
end
    
function replot(src,event,img,orig)
    [m,n] = size(img);
    newImg = im2double(orig);
    thresh = get(src,'Value')
    imgThresh = newImg;
    imgThresh(newImg<thresh) = 0;
    imgThresh(newImg>=thresh) = 256;
    plotFrame(imgThresh,thresh,orig);
end

function measureVelocity(src,event,thresh)
    close all;
    global mov frames gpThresh xCenter yCenter sizes flag minx miny maxx maxy maxPix avePix startFrame endFrame gpDoub;
    thresh
    xCenter = [];
    yCenter = [];
    for f = startFrame:endFrame
        [p,m] = frame2im(mov(f));
        gp = rgb2gray(p);
        gpDoub = im2double(gp);
        gpThresh = gpDoub;
        gpThresh(gpDoub<thresh) = 0;
        gpThresh(gpDoub>=thresh) = 256;
        
        [m,n] = size(gpThresh);
        sum = 0;
        flag = 0;
        xFlag = [];
        yFlag = [];
        for i = 2:m-1
            for j = 2:n-1
                if gpDoub(i,j) > maxPix(f)
                        maxPix(f) = gpDoub(i,j)*255;
                end
                
                
                if gpThresh(i,j) == 0
                    sum = sum + 1;
                    flag = flag + 1;
                    minx = 9999;
                    miny = 9999;
                    maxx = 0;
                    maxy = 0;
                    avePix(f,flag) = 0;
                    search(f,i,j,0,flag,0,0)
                    xCenter(f,flag) = 1/2*(minx+maxx);
                    yCenter(f,flag) = 1/2*(miny+maxy);
                    xFlag = [xFlag j];
                    yFlag = [yFlag i];
                end
            end
        end
        if (f == startFrame || f == endFrame)
        doubThresh = double(gpThresh);
        figure
        imshow(doubThresh);
        hold
        plot(xCenter(f,:),yCenter(f,:),'or','MarkerSize',1);
        end
    end  
    %findAvePix()
    findV() 
    findh()
end
    
function search(f,i,j,sz,thisFlag,sumx,sumy)
    global gpThresh width height xCenter yCenter sizes maxx maxy minx miny avePix gpDoub;
    size = sz + 1;
    sizes(f,thisFlag) = size;
    sumx = sumx + j;
    sumy = sumy + i;
    if ( j > maxx) maxx = j;
    end
    if ( j < minx) minx = j;
    end
    if ( i > maxy) maxy = i;
    end
    if( i < miny) miny = i;
    end
    %Find a smarter way to do this.
    gpThresh(i,j) = thisFlag/500;
    if j ~= 1
    if(gpThresh(i,j-1) == 0)
        search(f,i,j-1,size,thisFlag,sumx,sumy);
    end
    end
    if j ~= width
    if(gpThresh(i,j+1) == 0)
        search(f,i,j+1,size,thisFlag,sumx,sumy);
    end
    end
    if i ~= height
    if(gpThresh(i+1,j) == 0)
        search(f,i+1,j,size,thisFlag,sumx,sumy);
    end
    end
    if (i ~= 1)
    if(gpThresh(i-1,j) == 0)
        search(f,i-1,j,size,thisFlag,sumx,sumy);
    end
    end
end

function findAvePix()
    global xCenter yCenter avePix mov startFrame endFrame;
    [frm,flg] = size(xCenter);
    for f = startFrame:endFrame
        [p,m] = frame2im(mov(f));
        gp = rgb2gray(p);
        gpDouble = im2double(gp);
        for num = 1:flg
            for j = uint8(floor(xCenter(f,num)))-20:uint8(floor(xCenter(f,num)))+20
                for i = uint8(floor(yCenter(f,num)))-20:uint8(floor(yCenter(f,num)))+20
                    avePix(f,num) = avePix(f,num) + gpDouble(i,j)*255;
                end
            end
            avePix(f,num) = avePix(f,num)/(40^2);
        end
    end
end

function findV()
    global frames flag fps pixperum xCenter yCenter vel aveVel startFrame endFrame avePix sizes duration shortv avev stdv;
    vel = zeros(frames-1,flag);
    
%     for f = startFrame:endFrame
%         for s = 1:flag
%             vel(f,s) = sqrt((xCenter(f,s)-xCenter(f+1,s))^2+(yCenter(f,s)-yCenter(f+1,s))^2)*fps/pixperum;
%         end
%     end
    
    aveVel = zeros(flag,1);
%     for s = 1:flag
%         sum = 0;
%         for f = 1:frames-1
%             sum = sum + vel(f,s);
%         end
%         aveVel(s) = sum/(frames-1);
%     end
    shortv = zeros(5,1);
    for s = 1:flag
        factor = (endFrame-startFrame)/4;
        aveVel(s) = sqrt((xCenter(startFrame,s)-xCenter(startFrame+factor,s))^2+(yCenter(startFrame,s)-yCenter(startFrame+factor,s))^2)/(50)*fps/pixperum;
        shortv(1) = aveVel(s);
        aveVel(s) = sqrt((xCenter(startFrame+factor,s)-xCenter(startFrame+factor,s))^2+(yCenter(startFrame+factor,s)-yCenter(startFrame+factor,s))^2)/(50)*fps/pixperum;
        shortv(2) = aveVel(s);
        aveVel(s) = sqrt((xCenter(startFrame+factor,s)-xCenter(startFrame+factor,s))^2+(yCenter(startFrame+factor,s)-yCenter(startFrame+factor,s))^2)/(50)*fps/pixperum;
        shortv(3) = aveVel(s);
        aveVel(s) = sqrt((xCenter(startFrame+factor,s)-xCenter(startFrame+factor,s))^2+(yCenter(startFrame+factor,s)-yCenter(startFrame+factor,s))^2)/(50)*fps/pixperum;
        shortv(4) = aveVel(s);
        aveVel(s) = sqrt((xCenter(startFrame+factor,s)-xCenter(startFrame+factor,s))^2+(yCenter(startFrame+factor,s)-yCenter(startFrame+factor,s))^2)/(50)*fps/pixperum;
        shortv(5) = aveVel(s);
        avev = mean(shortv);
        stdv = std(shortv);
        
        xStart = xCenter(startFrame,s) 
        yStart = yCenter(startFrame,s)
        xEnd = xCenter(endFrame,s)
        yEnd = yCenter(endFrame,s)
    end
end

function findh()
global maxPix stdevh meanh startFrame endFrame;
lam = 632;
theta = pi/4+pi/8;
n1 = 1.52;
n2 = 1.33;
beta = 4*pi/lam*sqrt((n1*sin(theta))^2-n2^2);
factor = (402-381)/3; %px/um
I0 = 255;
r = 4.15;

I = maxPix(startFrame:endFrame,1);
h = log(I/I0)./-beta;
meanh = mean(h);
stdevh = std(h);
end





