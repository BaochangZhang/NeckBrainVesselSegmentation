function [Imax,Imin,N2] = peaks_Histogram(N)%======���ԸĽ�һ�¡�
% ����3D-CTCAֱ��ͼ���ߵķ�ֵ��͹�ֵ��Imax,Imin
N2 = smooth(N,10,'loess'); %21
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
end