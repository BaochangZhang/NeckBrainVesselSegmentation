function [Dx,vessel] = ICM_MRA(IMG,Iout,K,Object,SelecNum,NB,alfa,gama,IL,MPL_alfa,Beta_ini,iterations)

% �������壺ֻ�����ָ��Բ�MRA�����е�Ѫ��
% ������Iout_vessel_perscent��������Ѫ�ܵĳ�ʼ��ֵ�������ʼ��ֵthrethold
% ��run_ICM_MRA_segmentation�����𣺲���MPL��ȫ�Զ����Ƹ߼�MRFģ�Ͳ���
% IoutΪѪ����Ӧ������Frangi�Ķ�߶�Ѫ����ǿ�����õ�
% KΪ�ܵķ�������ObjectΪ�ָ�Ŀ����ţ��˺������Ѫ����Object=4��
% alfa:��߶�Ѫ���˲���Ӧ��ֵ�ļ�Ȩϵ����һ��Ϊ1.5
% ͨ�� SelecNum = [1 2 3 4];
% ʾ���� Dx = ICM_MRA(Img,Iout,4,4,[1 2 3 4],6,1.5,0.01,3,0.3,0);
Iout = double(Iout);
IMG = double(IMG);
close all; pause(0.1);
c = size(IMG,3);
%----------------------------------------- ���ݷ��ࣺ���������ֵ���������ϵ��
[VBN_EM,criValue,~] = SegParameter_MRA_pdf_curl(IMG,Iout,K,alfa,iterations);%����IMG���ݵķ������������������ϡ��������£���ʾfigure(1~3)
VBN = VBN_EM;
[flagIMG] = GetRegion(Iout,gama*criValue); % ��ȡ����ֲ��ռ�flagIMG,criValueΪ�ٽ���ֵ
% flagIMG=ones(size(IMG));
[Dx_MLE,sort_D] = ML_estimation(IMG,VBN,Object,flagIMG);  % ������Ȼ���Ƶĳ�ʼ��ǳ�
inPLX = sort_D(:,5);%
pxl_k = sort_D(:,1:4);
figure(4);imshow_Process(IMG,Iout,Dx_MLE);pause(0.5);
% figure(4);subplot(2,1+LSN,2+LSN);imshow3D_patch(flagIMG,flagIMG,[0.5 0.5 0.5]);title('Ѫ�ֲܷ���ʼ�ռ�');pause(1);% ��ʾѪ�ܵ�3D��ʼ�ռ�
disp(['��ѡ�ռ�������Ϊ' num2str(length(find(flagIMG==1))) '�� ��������Ϊ' num2str(numel(flagIMG)) '����ѡ�ռ����Ϊ' num2str(100*length(find(flagIMG==1))/numel(flagIMG)) '%']);
% figure(5);[OptiumBeTa] = BeTa_estimation(IMG,VBN,flagIMG,4,Dx_init,NB,MPL_alfa,Beta_ini);
%  OptiumBeTa = 0.3;
OptiumBeTa = (NB==6)*0.7 +(NB==0)*0.7 + (NB==26)*0.19;
disp(['OptiumBeTa = ' num2str(OptiumBeTa)]);

figure(6);% �ڽز�ͼ������ʾ�������
Dx_init = Dx_MLE;
for t = 1:IL
    tic;
    disp(['BeTa = ' num2str(OptiumBeTa) ';' 'ICM iteration ' num2str(t) ' times...']); 
    Dx = ICM_estimation(VBN,pxl_k,inPLX,Object,Dx_init,OptiumBeTa,NB);
    subplot(1,IL,t);imshow(Dx(:,:,fix(c/2)),[]); pause(0.2);
    title(['MRF-ICM����' num2str(t) '��' ]); 
    Dx_init = Dx;
    ti = toc;disp(['Iteration runtime = ' num2str(ti)]);
end
vessel=OveralShows(SelecNum,Dx,Dx_MLE,flagIMG,Object);
disp('----------- All FINISHED -------------------------');


%**************** SubFunction ML_estimation **********************************
function [Dout,sort_D] = ML_estimation(A,VBN,Object,flagIMG)
% �������壺���м��������Ȼ����
% A,����������Ѫ�ܺͱ���������ݣ�
% VBN3�������ֵ�ͷ��
% W��������ϵ��
% sort_D:��Ȼ���ʺ�ͷ������IndexA�ĺϳɾ�����length(IndexA)�У�Object+1��
tic;
disp('ML_estimation ...');
Dout = zeros(size(A));
IndexA = find(flagIMG~=0);%ȡ��flagIMG���Ϊ1����������
% IndexA = Index_head;
N = numel(IndexA);
L = size(VBN,1);
A = repmat(A(IndexA)',L,1);                                                % A���ΪL��1�е�A(:)'����
mu = repmat(VBN(:,1),1,N);                                                 %����L��Ni�е�mu����
sigma = repmat(VBN(:,2),1,N);                                              %����L��Ni�е�sigma����
W = repmat(VBN(:,3),1,N);                                                  %����L��Ni�е�W����
Li = find(1:L~=Object)';                                                   % ����1��K-1��
pxl_k = [W(1,:).*((A(1,:)./mu(1,:))).*exp(-(A(1,:).^2./(2*mu(1,:)))); ...
         W(2:4,:).*(1./sqrt(2*pi*sigma(2:4,:).^2)).*exp(-(A(2:4,:)-mu(2:4,:)).^2./(2*sigma(2:4,:).^2))];
% DMPL_vector = Object*((pxl_k(Object,:)./W(Object,:))>(sum(pxl_k(Li,:),1)./sum(W(Li,:),1)));%��һ�֣�Ȩƽ��Լ��Ŀ��ͱ�����
DMPL_vector = Object*(pxl_k(Object,:)>max(pxl_k(Li,:),[],1));%�ڶ��֣�Ѫ������ڱ���������ֵ
% DMPL_vector = Object*(pxl_k(Object,:)>sum(pxl_k(Li,:),1)/(L-1));%�����֣�Ѫ������ڱ�����ľ�ֵ,��������һ���㷨Ч������
Dout(IndexA)= DMPL_vector';%��ʸ�����������ֵ
index_PLX_object = [pxl_k' IndexA];% ���flagIMG==1�Ŀռ����أ������������飬��һ����pxl_k(Object)���ڶ��������صı��
sort_D = sortrows(index_PLX_object,-4);%��ȥ�ԿǺ�Ŀռ��У�����Ŀ���ࣨpxl_k��:,4�����ɸ����͵�˳���������
t = toc;
disp(['finished, time consumption of this step is ' num2str(t) ' s']);

%**************** SubFunction ICM_estimation **********************************
function [Dnew] = ICM_estimation(VBN,pxl_k,Ni,Object,D,beta,NB)
% A,����������Ѫ�ܺͱ���������ݣ�
% flagIMG����ʴ����ͼD1_EM�Ŀռ䣨�������ࣩ�����ų��˾�ֵ��͵�������𣬲���1�������ռ䣬0�������ռ�
% D,�ο���׼���ݣ�Ѫ�ܺͱ����ֱ�Ϊ��4���ͣ�3,2,1����
% beta��������ϵ����
W = VBN(:,3);
Li = 1:Object-1;%��Ŀ��������
sizeD = size(D);
Dnew = zeros(sizeD);
[a,b,c] = ind2sub(sizeD,Ni);
s = [a b c];
FN = (NB == 0)*3 + (NB == 6)*1 +(NB == 26)*2;%�Զ��庯�����
f={@clique_6 @clique_26 @clique_MPN};%�Զ������ź���
for n = 1:length(Ni)
    [pB,pV] = f{FN}(Object,s(n,:),D,beta);
    post_V = pV*pxl_k(n,4)/W (Object);
    post_B = pB*sum(pxl_k(n,Li'))/sum(W(Li'));
    Dnew(Ni(n)) = Object * (post_V >post_B);
end

%****************** SubFunction BeTa_estimation *************************
function [OptiumBeTa] = BeTa_estimation(IMG,VBN,flagIMG,Object,Dx_init,NB,MPL_alfa,Betaini)
% ���ý��������ԭʼ���ݹ������Ų�����
% ��ʱVBN�еı��������仯�ϴ�Ӧ�Խ���������������¹��Ʋ���
% ԭʼ�������IMG�������Ȼ�ռ�J����ʼ��ǳ�Dx_init�ĳߴ綼Ϊ��I_max*J_max*K_max
% BeTa��beta�������飻
% M:��ż����Ϊ1����ά����;
% OptiumBeta,���Ƶõ�������Betaֵ
% MPL_alfa�ϴ�ʱ���������²�����beta���ڽϴ�λ���������磺MPL_alfa=0.5ʱ��������0.8��MPL_alfa=0.1ʱ��������0.3��
% Betainiһ��Ϊ�㣬���ײ����ֲ���ֵ������Ϊ0.3ʱ��Խ����ֵ
[I_max,J_max,K_max] = size(IMG);
img = IMG(1:2:I_max,1:2:J_max,1:2:K_max);% ������IMG
[i_max,j_max,k_max] = size(img);% ���������img�ߴ�
flagIMG = flagIMG(1:2:I_max,1:2:J_max,1:2:K_max);% ������J
Dx_init = Dx_init(1:2:I_max,1:2:J_max,1:2:K_max);% ������Dx_init
M = Neighbor_0_1([i_max,j_max,k_max]);% ��������֮��i+j+k��ż����Ϊ1������
L = size(VBN,1);
mu = VBN(:,1);
sigma = VBN(:,2);
W = VBN(:,3);
Li = find(1:L~=Object);
N = cell(2,1);
N{1} = find(flagIMG==1 & M==0);%MRA���ݿռ���������
N{2} = find(flagIMG==1 & M==1);%MRA���ݿռ�ż�������
P = cell(2,1);
[x,y,z] = ind2sub([i_max,j_max,k_max],N{1});%����MRA���ݿռ���������[x,y,z]
P{1} = [x,y,z];
[x,y,z] = ind2sub([i_max,j_max,k_max],N{2});%����MRA���ݿռ���������[x,y,z]
P{2} = [x,y,z];

FN = (3)*(NB==0)+1*(NB==6)+2*(NB==26);
f={@clique_6 @clique_26 @clique_MPN};

upNum = 6;
LnPL = zeros(upNum,1);LnPLk = zeros(2,1);
dMPL = zeros(upNum,1);dMPLk = zeros(2,1);
Beta = zeros(upNum,1);Beta(1) = Betaini;% ����ֵBetaini 
disp(['Betaini= ' num2str(Betaini)]);
for i = 2:upNum % ���²������Ʋ��õ������㹫ʽ����MRA�еĲ������ƺ�run_ICM_phantom_1�еĶ���ͬ
    for k = 1:2 
       Lc = length(N{k});
       sumVB_delta=eps;nV=eps;nB=eps;Eg=eps;
       for t = 1:Lc
           n = N{k}(t);            
           pxl_k = [(img(n)/mu(1))*exp(-img(n)^2/(2*mu(1)));...
                   (1./sqrt(2*pi*sigma(2:4).^2)).*exp(-(img(n)-mu(2:4)).^2./(2*sigma(2:4).^2))]; 
           s = P{k}(t,:);
           [pB,pV,NsigmaV,NsigmaB] = f{FN}(Object,s,Dx_init,Beta(i-1));
           fV = pxl_k(Object)+eps;
           fB = sum(W(Li).*pxl_k(Li))/sum(W(Li))+eps;
           post_V = fV * pV;
           post_B = fB * pB; 
           nV = nV + (post_V>post_B);
           nB = nB + (post_V <= post_B);
           BetaSigmaV = Beta(i-1)*NsigmaV;
           BetaSigmaB = Beta(i-1)*NsigmaB;
           expV = exp(-BetaSigmaV);
           expB = exp(-BetaSigmaB);
           %----------------����α��Ȼ��������1���䵼��sumVB_delta     
           Eg = Eg + (post_V>post_B)*(- reallog(post_V));%α��Ȼ��������1                              
           sumVB_delta = sumVB_delta + (post_V>post_B)*((NsigmaV*fV*expV + NsigmaB*fB*expB)/(fV*expV + fB*expB)-NsigmaV);%α��Ȼ��������1�ĵ���
       end
       LnPLk(k) = Eg/Lc;
       dMPLk(k) = sumVB_delta/nV;
    end
    LnPL(i) = mean(LnPLk);
    dMPL(i) = mean(dMPLk);
    dMPL(1) = 1.2*dMPL(2);%��dMPL(1)=1.2*dMPL(2);
    delta_dMPL = abs(dMPL(i))- abs(dMPL(i-1));
    alfa_i = (i==2)*MPL_alfa*abs(1/dMPL(2)) + (i>2)*MPL_alfa*abs((1/(abs(dMPL(2))-abs(dMPL(i))+eps)));
    Beta(i) = Beta(i-1) - (delta_dMPL<=0)*alfa_i*delta_dMPL;
    disp(['No.' num2str(i) '--- dMPL(' num2str(i) ')= ' num2str(dMPL(i)) '; alfa_i = ' num2str(alfa_i) '; Beta(' num2str(i) ')= ' num2str(Beta(i))]);
end
OptiumBeTa = Beta(i);
mindMPL = min(dMPL(2:upNum));maxdMPL = max(dMPL(2:upNum));deltaMPL = 0.5*abs(maxdMPL-mindMPL);
subplot(1,2,1);plot(1:upNum,Beta,'r');axis([1 upNum 0 1.2*max(Beta)]);xlabel('Iteration times');ylabel('beta');
subplot(1,2,2);plot(1:upNum,dMPL,'r');axis([2 upNum mindMPL-deltaMPL maxdMPL+deltaMPL]);xlabel('Iteration times');ylabel('Derivative of negative logarithm of PL');
% subplot(1,3,3);plot(1:upNum,LnPL,'k');axis([2 upNum 1.1*min(LnPL) 1.1*max(LnPL)]);xlabel('Iteration times');ylabel('Eg');
t3 = toc;
disp(['End of BeTa_estimation_1. The estimation time = ' num2str(t3) ' s']);

%****************** SubFunction cliqueMPN *************************
function [pB,pV,NsigmaV,NsigmaB] = clique_MPN(K,s,D,beta)
% �ھ�ֵˮƽmu(k)�£��ֱ�����s������Ѫ��Ŀ��ĸ���pV�����ڱ����ĸ���pB
% KΪĿ����ı�ǣ�AΪ���ָ�ͼ��DΪ��ʼ��ǳ�
% flag =0������s�㼰�������ڱ����У�
% flag~=0������s�㼰��������Ŀ���У�
%% NsigmaV,Ŀ�������NsigmaB����������
[i_max,j_max,n_max] = size(D);
i = s(1);j = s(2);n = s(3);
ip = (i+1<=i_max)*(i+1)+(i+1>i_max);im = (i-1>=1)*(i-1)+(i-1<1)*i_max;%----�мӺͼ�
jp = (j+1<=j_max)*(j+1)+(j+1>j_max);jm = (j-1>=1)*(j-1)+(j-1<1)*j_max;%----�мӺͼ�
np = (n+1<=n_max)*(n+1)+(n+1>n_max);nm = (n-1>=1)*(n-1)+(n-1<1)*n_max;%----��Ӻͼ�
% �ڼȶ���26��������D_nb26�У�����ռ�����ľ���ṹ
A = [5 11 13 15 17 23]; % D_nb26�е�6�����㣻
% ��(i,j,n)Ϊ���ģ���26������������ɺ���ǰ���������ҡ��������Ϸ�Ϊ8�������壬ÿ���������(i,j,n)����7������,������Ķ�����ֵö�����£�
C = [1 2 4 5 10 11 13;2 3 5 6 11 12 15;4 5 7 8 13 16 17;5 6 8 9 15 17 18;...
     10 11 13 19 20 22 23;11 12 15 20 21 23 24;13 16 17 22 23 25 26;15 17 18 23 24 26 27];
% ��(i,j,n)Ϊ���ģ���26������������ɺ���ǰ���������ҡ��������Ϸ�Ϊ6�������壬ÿ���������(i,j,n)����9������,������Ķ�����ֵö�����£�
F = [4 5 10 11 13 16 17 22 23;5 6 11 12 15 17 18 23 24;2 5 10 11 12 13 15 20 23; ...
     5 8 13 15 16 17 18 23 26;2 4 5 6 8 11 13 15 17;11 13 15 17 20 22 23 24 26]; 
 
D_nb26 = [D(im,jm,nm) D(i,jm,nm) D(ip,jm,nm) D(im,j,nm) D(i,j,nm) D(ip,j,nm) D(im,jp,nm) D(i,jp,nm) D(ip,jp,nm) ... %3x3x3������ -1����ֵ
          D(im,jm,n)  D(i,jm,n)  D(ip,jm,n)  D(im,j,n)  D(i,j,n)  D(ip,j,n)  D(im,jp,n)  D(i,jp,n)  D(ip,jp,n) ...  %3x3x3������  0����ֵ
          D(im,jm,np) D(i,jm,np) D(ip,jm,np) D(im,j,np) D(i,j,np) D(ip,j,np) D(im,jp,np) D(i,jp,np) D(ip,jp,np)];   %3x3x3������ +1����ֵ          
% flag = sum(D_nb26(A)==K); % ͳ�����ĵ���Χ���ΪK�ĵ���(�Կռ�6����Ϊ��׼)
% 26������ά�ռ��N�����ż���--------------------- 
NsigmaV_6 = sum(D_nb26(A)==K);NsigmaB_6 = sum(D_nb26(A)~=K);
NsigmaV_7 = max([sum(D_nb26(C(1,:))==K) sum(D_nb26(C(2,:))==K) sum(D_nb26(C(3,:))==K) sum(D_nb26(C(4,:))==K) ...
                     sum(D_nb26(C(5,:))==K) sum(D_nb26(C(6,:))==K) sum(D_nb26(C(7,:))==K) sum(D_nb26(C(8,:))==K)]);% C���������µ�����
NsigmaB_7 = max([sum(D_nb26(C(1,:))~=K) sum(D_nb26(C(2,:))~=K) sum(D_nb26(C(3,:))~=K) sum(D_nb26(C(4,:))~=K) ...
                     sum(D_nb26(C(5,:))~=K) sum(D_nb26(C(6,:))~=K) sum(D_nb26(C(7,:))~=K) sum(D_nb26(C(8,:))~=K)]);% C���������µ�����      
NsigmaV_9 = max([sum(D_nb26(F(1,:))==K) sum(D_nb26(F(2,:))==K) sum(D_nb26(F(3,:))==K) ...
                     sum(D_nb26(F(4,:))==K) sum(D_nb26(F(5,:))==K) sum(D_nb26(F(6,:))==K)]);   % F���������µ�����
NsigmaB_9 = max([sum(D_nb26(F(1,:))~=K) sum(D_nb26(F(2,:))~=K) sum(D_nb26(F(3,:))~=K) ...
                     sum(D_nb26(F(4,:))~=K) sum(D_nb26(F(5,:))~=K) sum(D_nb26(F(6,:))~=K)]);   % F���������µ�����       
% D_nb26�о���A���������Ŀ��ͱ�������
Uv6 = 6-NsigmaV_6; Ub6 = 6-NsigmaB_6;
% D_nb26�о���C���������Ŀ��ͱ�������
Uv_bound1 = 7 - NsigmaV_7; Ub_bound1 = 7 - NsigmaB_7;
Uv_bound2 = 9 - NsigmaV_9; Ub_bound2 = 9 - NsigmaB_9;
% ����Ŀ����ʣ�����D(i,j,n)�Ƿ�ΪK����Χ���K�϶�ʱ��������С��Ŀ��������
Uvw = min([Uv6 Uv_bound1 Uv_bound2]);%Uvw = [Uv6 Uv_bound1 Uv_bound2];
Uv = beta*Uvw;
pV = exp(-Uv);
% ���㱳�����ʣ�����Χ��ǲ�ΪK�Ľ϶�ʱ��������С�������������
Ubw = min([Ub6 Ub_bound1 Ub_bound2]);%Ubw = [Ub6 Ub_bound1 Ub_bound2];
Ub = beta*Ubw;
pB = exp(-Ub);
% ����Ŀ�����NsigmaV�ͱ�������NsigmaB
NsigmaV = min([NsigmaV_6 NsigmaV_7 NsigmaV_9]);
NsigmaB = min([NsigmaB_6 NsigmaB_7 NsigmaB_9]);

%****************** SubFunction clique_26 *************************
function [pB,pV,NsigmaV,NsigmaB] = clique_26(K,s,D,beta)
% �ھ�ֵˮƽmu(k)�£��ֱ�����s������Ѫ��Ŀ��ĸ���pV�����ڱ����ĸ���pB
% KΪĿ����ı�ǣ�AΪ���ָ�ͼ��DΪ��ʼ��ǳ�
% flag =0������s�㼰�������ڱ����У�
% flag~=0������s�㼰��������Ŀ���У�

% --------��1��----------�����������꣬�ο�neighbouring2
[i_max,j_max,k_max] = size(D);
i = s(1);j = s(2);k = s(3);
%----�м�1�ͼ�1
ip = (i<i_max)*(i+1)+(i==i_max);
im = (i>1)*(i-1)+(i==1)*i_max;
%----�м�1�ͼ�1
jp = (j<j_max)*(j+1)+(j==j_max);
jm = (j>1)*(j-1)+(j==1)*j_max;
%----���1�ͼ�1
kp = (k<k_max)*(k+1)+(k==k_max);
km = (k>1)*(k-1)+(k==1)*k_max;
% ---------End��1��------------
D_nb26 = [D(im,jm,km) D(i,jm,km) D(ip,jm,km) D(im,j,km) D(i,j,km) D(ip,j,km) D(im,jp,km) D(i,jp,km) D(ip,jp,km) ... %3x3x3������ -1����ֵ
          D(im,jm,k)  D(i,jm,k)  D(ip,jm,k)  D(im,j,k)  D(i,j,k)  D(ip,j,k)  D(im,jp,k)  D(i,jp,k)  D(ip,jp,k) ...  %3x3x3������  0����ֵ
          D(im,jm,kp) D(i,jm,kp) D(ip,jm,kp) D(im,j,kp) D(i,j,kp) D(ip,j,kp) D(im,jp,kp) D(i,jp,kp) D(ip,jp,kp)];   %3x3x3������ +1����ֵ
% A = [5 11 13 15 17 23]; % D_nb26�е�6�����㣻
% flag = sum(D_nb26(A)==K); % ͳ�����ĵ���Χ���ΪK�ĵ���(�Կռ�6����Ϊ��׼)
NsigmaV = sum(D_nb26(1:27~=14)==K);
NsigmaB = sum(D_nb26(1:27~=14)~=K);
Uv26 = 26-NsigmaV;% ȥ�����ĵ�14��D_nb26�о���A��=D_nb26������26�����Ŀ������
Ub26 = 26-NsigmaB;% ȥ�����ĵ�14��D_nb26�о���A��=D_nb26������26����ı�������
% ����Ŀ����ʣ�����D(i,j,k)�Ƿ�ΪK����Χ���K�϶�ʱ��������С��Ŀ��������
Uv = beta*Uv26;
pV = exp(-Uv);
% ���㱳�����ʣ�����Χ��ǲ�ΪK�Ľ϶�ʱ��������С�������������
Ub = beta*Ub26;
pB = exp(-Ub);

%****************** SubFunction clique_6 *************************
function [pB,pV,NsigmaV,NsigmaB] = clique_6(K,s,D,beta)
% �ھ�ֵˮƽmu(k)�£��ֱ�����s������Ѫ��Ŀ��ĸ���pV�����ڱ����ĸ���pB
% KΪĿ����ı�ǣ�AΪ���ָ�ͼ��DΪ��ʼ��ǳ�
% fb��¼��s����Χ�����ǵıȽϣ���ͬ��fb=1����ͬ��fb=0
% flag =0������s�㼰�������ڱ����У�
% flag~=0������s�㼰��������Ŀ���У�
[i_max,j_max,n_max] = size(D);
i = s(1);j = s(2);n = s(3);
ip = (i+1<=i_max)*(i+1)+(i+1>i_max);im = (i-1>=1)*(i-1)+(i-1<1)*i_max;%----�мӺͼ�
jp = (j+1<=j_max)*(j+1)+(j+1>j_max);jm = (j-1>=1)*(j-1)+(j-1<1)*j_max;%----�мӺͼ�
np = (n+1<=n_max)*(n+1)+(n+1>n_max);nm = (n-1>=1)*(n-1)+(n-1<1)*n_max;%----��Ӻͼ�
% �ڼȶ���26��������D_nb26�У�����ռ�����ľ���ṹ
D_nb26 = [D(im,jm,nm) D(i,jm,nm) D(ip,jm,nm) D(im,j,nm) D(i,j,nm) D(ip,j,nm) D(im,jp,nm) D(i,jp,nm) D(ip,jp,nm) ... %3x3x3������ -1����ֵ
          D(im,jm,n)  D(i,jm,n)  D(ip,jm,n)  D(im,j,n)  D(i,j,n)  D(ip,j,n)  D(im,jp,n)  D(i,jp,n)  D(ip,jp,n) ...  %3x3x3������  0����ֵ
          D(im,jm,np) D(i,jm,np) D(ip,jm,np) D(im,j,np) D(i,j,np) D(ip,j,np) D(im,jp,np) D(i,jp,np) D(ip,jp,np)];   %3x3x3������ +1����ֵ
A = [5 11 13 15 17 23]; % D_nb26�е�6�����㣻 
% flag = sum(D_nb26(A)==K); % ͳ�����ĵ���Χ���ΪK�ĵ���(�Կռ�6����Ϊ��׼)
NsigmaV = sum(D_nb26(A)==K);
NsigmaB = sum(D_nb26(A)~=K);
% 26������ά�ռ��N�����ż���--------------------- 
Uv6 = 6-NsigmaV;% D_nb26�о���A����6�����Ŀ������
Ub6 = 6-NsigmaB;% D_nb26�о���A����6����ı�������
% fb = (Uv6~=0);
% ����Ŀ����ʣ�����D(i,j,n)�Ƿ�ΪK����Χ���K�϶�ʱ��������С��Ŀ��������
Uv = beta*Uv6;
pV = exp(-Uv);
% ���㱳�����ʣ�����Χ��ǲ�ΪK�Ľ϶�ʱ��������С�������������
Ub = beta*Ub6;
pB = exp(-Ub);

%****************** SubFunction Neighbor_0_1 *************************
function M = Neighbor_0_1(S)
M = zeros(S);
for i = 1:S(1)
    for j = 1:S(2)
        for n = 1:S(3)
            M(i,j,n)=(mod(i+j+n,2)==1);
        end
    end
end

%****************** SubFunction MRA_SegParameter1 ********************

function [VBN_EM,criValue,paraV] = SegParameter_MRA_pdf_curl(IMG,Iout,K,alfa,iterations)

% �������壺��ʾCTCAֱ��ͼ��K��ֵ�����ࡢ�������ٷֱȡ���K��ֵ����ǰ��������EM����ȷ���Ʋ���
% Ŀ������ΪMRF�ָ��ṩ��ȷ����mu��sigma��w
% ��ʾ�ز�ͼ���������ס��ͼfigure(1)�������������ͼfigure(2)��������������ͼfigure(3)
% threthold = theta * criValue,criValueΪ�ٽ���ֵ
close all
%%%%%%%%%%��ʾCTCAֱ��ͼ
[a,b,c] = size(IMG);
img = IMG(1:2:a,1:2:b,1:2:c);% ���󽵲���
LengthIMG = numel(img);
Max_img = max(img(:));
[~,~,c] = size(img);
figure(1);
subplot(1,2,1);imshow(imrotate(img(:,:,fix(c/4)),-90),[]);
[N,X] = hist(img(:),0:Max_img); 
%%%%%%%%%%%��ʾֱ��ͼ�ϵļ���
[Imax,Imin,N2] = peaks_Histogram(N);
hc = N2'/LengthIMG;
LN = length(hc);
subplot(1,2,2);
plot(1:LN,hc,'-b','LineWidth',2);hold on % ��ʾֱ��ͼ����
plot(Imax,hc(Imax),'*r','MarkerSize',3);
plot(Imin,hc(Imin),'ob','MarkerSize',3);
axis([0 Max_img 0 max(hc)+0.1*max(hc)]);
grid on;axis square;hold off;
disp('[Imax(1) Imin Imax(2)] = ');
disp(num2str([Imax(1) Imin Imax(2)]));
%%%%%%%%%% K��ֵ���࣬����������ֵ K_mu��������K_var�ٷֱ�K_percent
tic;
disp('kmeans...')
[idx,ctrs] = kmeans(img(:),K,'start',[Imax(1);Imin;Imax(2);350]);%4����ʼ�����[Imax(1);Imin;Imax(2);350]
[Idx,Ctrs] = Kmean_reorder(idx,ctrs);% ���ջҶ��������ɵ����ߵ�˳���������idx��ctrs
K_mu = Ctrs;
Beta = Imax(1);%��������ϳɷֵĲ���
K_var = zeros(K,1);% ����
K_sigma = zeros(K,1);%��׼��
Omega = zeros(K,1);%Ϊ��ϳɷ�ռ��
RG_K_curl = zeros(K,LN);
% figure(2);
% subplot(1,2,1);
figure;
plot(1:LN,hc,'-k','LineWidth',1.5);% ��ʾֱ��ͼ����
axis([0 400 0 max(hc)+0.1*max(hc)]);grid on;hold on;
flag = {'-.b';'-.c';'-.m';'-g';'-r';'-k';'-.k';'-.y';'--k';':k';':g'};
for i = 1:K % ������������K_var���ٷֱ�K_percent�����˹����ͼ
    Omega(i) = length(find(Idx==i))/LengthIMG;% ������ֲ����ߵ����ֵ
    K_var(i) = var(img(Idx==i));
    K_sigma(i) = sqrt(K_var(i));
    RG_K_curl(i,:) = (i==1)*Omega(i)*(X./Beta^2).*exp(-(X.^2./(2*Beta^2)))+...
                   (i~=1)*Omega(i)*(1/sqrt(2*pi)/K_sigma(i)).*exp(-(X-K_mu(i)).^2/(2*K_var(i)));%����RGMM������˹���ģ��
    plot(1:LN,RG_K_curl(i,:),char(flag(i)),'LineWidth',1);%���Ƹ�����ֲ�����
end
t = toc; disp(['using ' num2str(t) '��']);
legend_char = cell(K+2,1);
legend_char{1} = char('Original histogram');
for i = 1:K % �༭legend
    if i==1
        legend_char{1+i} = char(['Rayleigh curl-line' num2str(i) ': beta=' num2str(uint16(Beta))...
          ' w=' num2str(Omega(i))]);
    else
        legend_char{1+i} = char(['Gaussian curl-line' num2str(i) ': mu=' num2str(uint16(K_mu(i)))...
          ' sigma=' num2str(uint16(K_sigma(i))) ' w=' num2str(Omega(i))]);
    end
end
plot(1:LN,sum(RG_K_curl,1),'--r','LineWidth',1);% ��ʾ��Ϻ������
legend_char{K+2} = char('Init-fitting histogram');
legend(legend_char{1:K+2});
xlabel('Intensity');
ylabel('Frequency');
hold off

VBN_Init = [Beta^2     0         Omega(1);
            K_mu(2)  K_sigma(2)  Omega(2);
            K_mu(3)  K_sigma(3)  Omega(3);
            K_mu(4)  K_sigma(4)  Omega(4)];

% VBN_Init(4,1) = alfa*VBN_Init(4,1);%����ֵ 1.5*VBN_Init(4,1);
[criValue,paraV] = Iout_vessel_perscent(IMG,Iout,Omega(4),alfa); % threthold = theta * criValue,criValueΪ�ٽ���ֵ

VBN_Rect = [Beta^2     0         Omega(1);
            K_mu(2)  K_sigma(2)  Omega(2);
            K_mu(3)  K_sigma(3)  Omega(3);
            paraV(1) paraV(2)    Omega(4)];

%%%%%%%%%%%%%%���������������ȷ�������ϸ�����K_mean��K_sigma��K_percent
disp('RGMM_EM...');tic;
[VBN_EM, SumError] = RGMM_EM(IMG,VBN_Rect,iterations,0);%����ԭʼ��ߴ�����IMG���㾫ȷ���� %RGMM_EM(IMG,VBN_Init,1000,1);RGMM_EM(IMG,VBN_Rect,500,0)
% disp(['Finished, the curl_lines fitting error after EM step is: ' num2str(minError)]);
EM_mu = zeros(K,1);
EM_var = zeros(K,1);
EM_sigma = zeros(K,1);
Omega = zeros(K,1);
RG_EM_curl = zeros(K,LN);
% figure(3);
% subplot(1,2,2);
figure;
plot(1:LN,hc,'-k','LineWidth',1.5);% ��ʾֱ��ͼ����
axis([0 400 0 max(hc)+0.1*max(hc)]);grid on;hold on;
for i = 1:K % ��������ֵK_mean��������K_sigma�ٷֱ�K_percent
    EM_mu(i) = VBN_EM(i,1);
    Omega(i) = VBN_EM(i,3);% ������ֲ����ߵ����ֵ
    EM_var(i) =  VBN_EM(i,2)^2+eps(1);
    EM_sigma(i) = VBN_EM(i,2)+eps(1);
    RG_EM_curl(i,:) = (i==1)*Omega(i)*(X./EM_mu(i,1)).*exp(-(X.^2./(2*EM_mu(i,1))))+...
                   (i~=1)*Omega(i)*(1/sqrt(2*pi)/EM_sigma(i)).*exp(-(X-EM_mu(i)).^2/(2*EM_var(i))); 
    plot(1:LN,RG_EM_curl(i,:),char(flag(i)),'LineWidth',1);
end
t = toc; disp(['using ' num2str(t) '��']);
legend_char = cell(K+2,1);
legend_char{1} = char('Original histogram');
for i = 1:K % % �༭legend
    if i==1
       legend_char{1+i} = char(['EM Rayleigh curl-line ' num2str(i) ': beta=' num2str(uint16(sqrt(EM_mu(i))))...
           ' w=' num2str(Omega(i))]);
    else
       legend_char{1+i} = char(['EM Gaussian curl-line ' num2str(i) ': mu=' num2str(uint16(EM_mu(i)))...
           ' sigma=' num2str(uint16(EM_sigma(i))) ' w=' num2str(Omega(i))]);
    end
end
plot(1:LN,sum(RG_EM_curl,1),'--r','LineWidth',1);% ��ʾ��Ϻ������
legend_char{K+2} = char('EM fitting histogram');
legend(legend_char{1:K+2});
xlabel('Intensity');
ylabel('Frequency');
hold off

%----���Kmeans�Ĳ������ƽ��
VBN_Initshow = VBN_Init;
VBN_Initshow(1,1) = Beta;
disp('VBN_Init =');disp(num2str(VBN_Initshow));
disp(['VBN_Init by KmeansSize: [' num2str(size(img)) ']']);
%----���������Ĳ������ƽ��
VBN_Rectshow = VBN_Rect;
VBN_Rectshow(1,1) = Beta;
disp('VBN_Rect =');disp(num2str(VBN_Rectshow));
disp(['VBN_Init by RectSize: [' num2str(size(IMG)) ']']);
%----�����������������ƽ��
VBN_EM_show = VBN_EM; 
VBN_EM_show(1,1) = sqrt(VBN_EM(1,1));
disp('VBN_EM =');disp(num2str(VBN_EM_show));
disp(['VBN_EM by EMSize: [' num2str(size(IMG)) ']']);
%---------------
disp(['All over. The EM Fitting error is ' num2str(SumError)]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% �Ӻ���1%%%%%%%%%%%%%%%%%%
function [Imax,Imin,N2] = peaks_Histogram(N)%======���ԸĽ�һ�¡�
% ����3D-CTCAֱ��ͼ���ߵķ�ֵ��͹�ֵ��Imax,Imin
N2 = smooth(N,32,'loess'); %21
LN = length(N2);
DN2 = diff([N2;N2(LN)]);
n1 = 0;
n2 = 0;
I_max=[];
I_min=[];
I_MIN=[];
for i = 5:200 % �ӵ�10���㿪ʼ 200=>length(N2)-2
    if ((DN2(i-1)>0) && (DN2(i+1)<0)) && N2(i)>max(N2(i-1),N2(i+1)) && N2(i)>10
       n1 = n1+1;
       I_max(n1) = i;
    end
    if ((DN2(i-1)<0) && (DN2(i+1)>0)) && N2(i)<min(N2(i-1),N2(i+1))
       n2 = n2+1;
       I_min(n2) = i;
    end 
end
% �ڸ�����ֵ��I_max֮���ҳ����ŵĹȵ�
n_max = length(I_max); % ��ֵ����
for k = 1:n_max
    if k ~= n_max
       nums = find(I_min>I_max(k) & I_min<I_max(k+1));
       [~,m] = min(N2(I_min(nums)));
       I_MIN(k) = I_min(nums(m));
    end
    if k == n_max && ~isempty(find(I_min>I_max(k)))
       nums = find(I_min>I_max(k));
       [~,m] = min(N2(I_min(nums)));
       I_MIN(k) = I_min(nums(m));
    end
end
Imax = I_max;
Imin = I_MIN;

%**************** SubFunction Iout_vessel_perscent ***************************
function [criValue,paraV] = Iout_vessel_perscent(IMG,Iout,percentEM,alfa)
disp('computing the optiumal threthold,mu4,sigma4 ...');
[y,x,z] = size(Iout);
b = numel(Iout);
N = 100;
MultiplyNum = 10;% ��Ϊ����(��Ӱ��ָ���)�����Ա�subplot(1,2,1)����ʾ�����߱�ΪѪ����ͷ­�ݻ�������MultiplyNum=1Ϊ�͹���ʵֵ
Iout =Iout/max(Iout(:));%��һ��Ϊ[0,1]
thre_value = linspace(0.001,0.08,N);
ratio = zeros(N,1);
for i = 1:N
    Gi = GetRegion(Iout,thre_value(i)); % �����ֵthre_value(i)�µ����Ѫ�ܷ�֧��
    ratio(i) = MultiplyNum*length(find(Gi>thre_value(i)))/b;
end
[~,numr] = min(abs(ratio-MultiplyNum*percentEM));
figure(3);
subplot(1,2,1);plot(thre_value,ratio,'-b',thre_value,ratio(numr)*ones(1,N),'-.r',thre_value(numr),ratio(numr),'*r');
xlabel('threshold values');ylabel('ratios')
legend('ratio curve of cerebral vessel to head volume','ratio given by prior knowledge');
axis([min(thre_value) max(thre_value) 0 MultiplyNum*0.005])

criValue = thre_value(numr);                 % criValue��Ϊ�ٽ�㣬����������Ѫ�ܵĳ�ʼ����,��������gama*criValue����Ѫ����̽�ռ�
Stemp = GetRegion(Iout,criValue)>criValue;   % Ѫ�ܳ�ʼ�ռ�
IMG_mu4 = mean(IMG(Stemp));                  % IMG�е�Ѫ�ܾ�ֵ
IMG_sigma4 = std(IMG(Stemp));                % IMG�е�Ѫ�ܱ�׼��
paraV = [alfa*IMG_mu4,IMG_sigma4];

% ��ʾ'w4'��Ӧ�����Ѫ�ܷ�֧��
Gout = GetRegion(Iout,thre_value(numr));% ���'w4'��Ӧ��Ѫ�ܷ�֧��
subplot(1,2,2);patch(isosurface(Gout,0.5),'FaceColor','r','EdgeColor','none');
axis([0 x 0 y 0 z]);view([270 270]); daspect([1,1,1]);
camlight; camlight(-80,-10); lighting phong; pause(1); 
title('thresholding the multi-scale filtering response at the appointed ratio');
% view([0 -90]);
% view([270 270]); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%�Ӻ���2%%%%%%%%%%%%%%%%%

function [VBN, SumError] = RGMM_EM(B,Init,upNum,Flag)
% Flag=1:��ʾ������������ͼfigure(3)��������ʾ
% upNum:����������ֵ
% Init������֮ǰVBN�ĳ�ʼ������

K = size(Init,1);
N = length(B(:));
B_max = max(B(:));
[fc,xi] = hist(B(:),0:B_max);
L = length(0:B_max);

FC = M_Extand(fc,K,L);
XI = M_Extand(xi,K,L);

Mu = zeros(K,upNum+1);
Var = zeros(K,upNum+1);
W = zeros(K,upNum+1);
Error = zeros(1,upNum);
dL = length(Error);

Mu(:,1) = Init(:,1);
Var(:,1) = Init(:,2).^2;
W(:,1) = Init(:,3);

for i = 1:upNum
    [plx,pxl] = pLX(0:B_max,K,Mu(:,i),Var(:,i),W(:,i));
    W(:,i+1) = (1/N)*sum(FC.*plx,2);
    Mu(1,i+1) = sum(XI(1,:).^2.*FC(1,:).*plx(1,:),2)./(2*sum(FC(1,:).*plx(1,:),2));% (1,:)��Ӧ�����ֲ��ܶȺ���
%     Mu(2:K,i+1) = sum(XI(2:K,:).*FC(2:K,:).*plx(2:K,:),2)./sum(FC(2:K,:).*plx(2:K,:),2);% ����(2:K,:)��Ӧ�ĸ�˹��ֵ
    Mu(2:K-1,i+1) = sum(XI(2:K-1,:).*FC(2:K-1,:).*plx(2:K-1,:),2)./sum(FC(2:K-1,:).*plx(2:K-1,:),2);% ����(2:K-1,:)��Ӧ�ĸ�˹��ֵ
    Mu(K,i+1) = Mu(K,i);% ����K��Ӧ�ĸ�˹��ֵ
    MU = M_Extand(Mu(:,i+1),K,L);
    Var(2:K,i+1) = sum((XI(2:K,:)-MU(2:K,:)).^2.*FC(2:K,:).*plx(2:K,:),2)./sum(FC(2:K,:).*plx(2:K,:),2);
    Error(i) = sum(abs(sum(pxl,1)-fc/N));
end
VBN = [Mu(:,upNum+1) sqrt(Var(:,upNum+1)) W(:,upNum+1)];
% [minError,i_num] = min(Error);
% VBN_EM = [Mu(:,i_num+1) sqrt(Var(:,i_num+1)) W(:,i_num+1)];

if Flag==1
figure(3);
legend_char = cell(K+1,1);
subplot(1,3,1);plot(1:dL,Mu(:,1:dL));
for k = 1:K
    if k==1
       legend_char{k} = char(['beta updates from ' num2str(sqrt(Mu(k,1))) ' to ' num2str(sqrt(Mu(k,dL)))]);
    else
       legend_char{k} = char(['mu' num2str(k-1) ' updates from ' num2str(Mu(k,1)) ' to ' num2str(Mu(k,dL))]);
    end
end
legend(legend_char{1:K});
axis([0 dL+1 0 1.5*max(Mu(:))+20]);
xlabel('Times of EM iteration');
ylabel('Mean of each classification')

subplot(1,3,2);plot(1:dL,sqrt(Var(:,1:dL)));
for k = 2:K
    legend_char{k} = char(['sigma' num2str(k-1) ' updates from ' num2str(sqrt(Var(k,1))) ' to ' num2str(sqrt(Var(k,dL)))]);
end
legend(legend_char{2:K});
axis([0 dL+1 0 1.5*max(sqrt(Var(:)))+10]);
xlabel('Times of EM iteration');
ylabel('Sigma of each classification')

subplot(1,3,3);plot(1:dL,W(:,1:dL));
for k = 1:K
    legend_char{k} = char(['w' num2str(k) ' updates from ' num2str(fix(100*W(k,1))/100) ' to ' num2str(fix(100*W(k,dL))/100)]);
end
legend(legend_char{1:K});
axis([0 dL+1 0 1.2]);
xlabel('Times of EM iteration');
ylabel('Weight of each classification')

figure(4);
plot(1:dL,Error(1:dL));
axis([0 dL 0 max(Error)]);
xlabel('Times of EM iteration');
ylabel('MSE of the parameters between neiboring iteration')

end
SumError = Error(dL);

%***********************************************************************************
%************** �Ӻ�������������,f(k|xi) = wk*f(xi|k)/��j=1:K(wj*f(xi|j))*********
function [plx,pxl] = pLX(xi,K,Mu,Var,W)
% ���������ʾ���plx
pxl = zeros(K,length(xi));% ��ʼ���������ʾ���
plx = zeros(K,length(xi));% ��ʼ��������ʾ���
Var = Var + eps(1);       % ʹ�õ�һ�з���Ϊ�����������С��������1/sqrt(2*pi*Var(k))ΪNaN
for k = 1:K               % ���������������ʾ���
    pxl(k,:) = (k==1)*W(k)*(xi./Mu(1)).*exp(-(xi.^2./(2*Mu(1)))) + ...
               (k~=1)*W(k)*(1/sqrt(2*pi*Var(k)))*exp(-(xi-Mu(k)).^2./(2*Var(k)));
end
Sum_pxl = sum(pxl,1)+eps(1);
for k = 1:K
    plx(k,:) = pxl(k,:)./Sum_pxl;
end

function [D] = M_Extand(Vector,K,L)
% size(Vector) = [K,1] or [1,L]
% ��Vector��չΪ����D��size(D)=[K,L]
D = zeros(K,L);
[a,b] = size(Vector);
if a>1 && b==1 %���Vector��һ��ʸ��K��1
   for j = 1:L
       D(:,j) = Vector;
   end    
end
if a==1 && b>1 %���Vector��һ��ʸ��1��L
    for i = 1:K
        D(i,:) = Vector;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%�Ӻ���4 %%%%%%%%%%%%%%%%%%

function [Idx,Ctrs] = Kmean_reorder(idx,ctrs)
% �������壺��idx��ctrs�е����ݰ���ctrs��С�����˳����������
K = length(ctrs);
Ctrs_index = [ctrs,(1:length(ctrs))'];
sort_Ctrs = sortrows(Ctrs_index,1);% sort_Ctrs(:,1)�ɵ����ߴ�ž������ģ�sort_Ctrs(:,2)��Ŷ�Ӧ��ԭʼ����k
K_index = cell(1,K);
for k = 1:K % ��idx��ԭʼ�����k�ֱ�洢��K_index�ṹ��
    K_index{k} = find(idx==k);
end
Idx = zeros(size(idx));
Ctrs = zeros(size(ctrs));
for i = 1:K
    Ctrs(i) = sort_Ctrs(i,1);
    Idx(K_index{sort_Ctrs(i,2)}) = i;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% imshow_flagIMG %%%%%%%%%%%%%%%
function imshow3D_patch(D,D_original,colormode)
% D��D_original������ͬ�ߴ磻��[a,b,c] = size(D)
% ��ȡ3D��ֵ���ݿռ�D_original��0/1��ֵ���ߴ磬���ڴ˿ռ�����ʾD��Ŀ�ꣻ
index = find(D_original==1);
[a,b,c] = ind2sub(size(D_original),index);
mina = min(a);maxa = max(a);
minb = min(b);maxb = max(b);
minc = min(c);maxc = max(c);
F = zeros((maxa-mina+1)+9,(maxb-minb+1)+9,(maxc-minc+1)+9);
F(4:4+(maxa-mina),4:4+(maxb-minb),4:4+(maxc-minc)) = D(mina:maxa,minb:maxb,minc:maxc);
[a,b,c] = size(F);
patch(isosurface(F,0.5),'FaceColor',colormode,'EdgeColor','none');
axis([0 b 0 a 0 c]);view([270 270]);daspect([1,1,1]);
camlight; camlight(-80,-10); lighting phong; pause(1); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% GetRegion %%%%%%%%%%%%%%%
function [Gout,MaxLength] = GetRegion(Iin,threthold,SelecNum)
% ��Iin��ֵ������ȡ����Ŀ��飬���������ҳ��������Max_num�������������Iout����ֵ����
% T��ȡ����Ĵ�������k����ȡk-1��ѡʣ�Ľ��
% TtΪ[1 2 ... T]�ĳ�Ա���飬��������ȡĿ�������
J = Iin>threthold;
sIdx  = regionprops(J,'PixelIdxList');      % ��ȡJ������Ŀ������������������
num_sIdx = zeros(length(sIdx),1);           % ���sIdx���ȵľ���num_sIdx
Gout = zeros(size(J));                      % �½�����ͬ�ߴ�ı�Ǿ���Iout
for i = 1:length(sIdx)
    num_sIdx(i) = length(sIdx(i).PixelIdxList);
end
if nargin ==2                               % ������ǰ��������ʱ
   [~,Max_num] = max(num_sIdx);             % �������num_sIdx�е���󳤶����
   MaxPatch = sIdx(Max_num).PixelIdxList;
   Gout(MaxPatch) = 1;                      % �������
   MaxLength = length(MaxPatch);            % �������ĳ���
   return;
end
MaxLength = [];
maxSN = max(SelecNum);                      % ѡ��������������
for t = 1:maxSN                             % Ѱ��ָ������
    [~,Max_num] = max(num_sIdx);            % ����ĳ���    
    num_sIdx(Max_num)=0;                    % ��num_sIdx���ҵ�������ĳ�����0���Ա����Ѱ�Ҵδ�ֵ            
   if ismember(t,SelecNum)                  % ���Ϊָ�������飬�����֮
      MaxPatch = sIdx(Max_num).PixelIdxList;
      Gout(MaxPatch) = 1;    % �γ������Ȼ�ռ䣨����1����
   end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% imshow_Process %%%%%%%%%%%%%%
function imshow_Process(IMG,Iout,Dx_init)
c = size(IMG,3);
subplot(1,4,1);imshow(imrotate(IMG(:,:,fix(c/2)),-90),[]);title('Original Image');
subplot(1,4,2);imshow(imrotate(squeeze(max(IMG,[],3)),-90),[]);title('MIP of Original Image');
subplot(1,4,3);imshow(imrotate(squeeze(max(Iout,[],3)),-90),[]);title('MIP after Vessel Enhance');
subplot(1,4,4);imshow(imrotate(Dx_init(:,:,fix(c/2)),-90));title('ML_estimation');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% OveralShows %%%%%%%%%%%%%%
function [vessel]=OveralShows(SelecNum,Dx,Dx_MLE,flagIMG,Object)
Dout = zeros([size(Dx) 2]);% DoutΪ0/4��ֵ����
[Dout(:,:,:,1)] = GetRegion(Dx,0,SelecNum);% ��������SelecNum(i)������Ѫ�ܷ�֧   
[Dout(:,:,:,2)] = GetRegion(Dx,0,[1 2 3]);% ����Ѫ�ܷ�֧  
figure;
subplot(1,3,1);imshow3D_patch(Dx_MLE,flagIMG,[1 0 0]);title('ML����');
subplot(1,3,2);imshow3D_patch(Object*Dout(:,:,:,1),flagIMG,[1 0 0]);title('Markov���������');
subplot(1,3,3);imshow3D_patch(Object*Dout(:,:,:,2),flagIMG,[1 0 0]);title('�����ͨ����');

%vessel=zeros([size(Dx) 1]);
vessel=Dout(:,:,:,2);
disp(['Length of cerebral vessel is ' num2str(length(find(Dout(:,:,:,2)==1))) ' voxels']);


