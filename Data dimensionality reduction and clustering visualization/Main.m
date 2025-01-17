%% ===========================清空工作区============================
clc;
clear;
close all;
addpath(genpath(pwd)); % 添加当前路径文件夹及其子文件夹
%% =============================数据导入============================
data = readcell('可视化som.csv');
X = data(2:end-2,1:end-2);         % 数据的特征
X = cell2mat(X);
FeaName = data(1,1:end-2);
Label = 1:1:size(X,1);
Label = num2cell(Label)';
%% ============================数据规范化===========================
X = som_normalize(X,'range');   % 归一化
%% =============================训练网络============================
sD = som_data_struct(X,'name','A DEMO',...     % 标准数据集
		     'comp_names',FeaName); % 注意这里特征的名称和特征的数量保持一致
MapSize = [12,12];
MapNum = MapSize(1)*MapSize(2);
sMap = som_make(sD,'munits', MapNum,'msize',MapSize,'mapsize','normal','footnote','');
%% ============================可视化SOM============================
%---------绘制U_MAT------------
figure()
% U矩阵是不同竞争层节点的距离矩阵
% colormap(mymap("coolwarm"))
colormap(mymap("rainbow"))
som_show(sMap,'umat','all','norm','d','footnote','')
%---------绘制各成分---------
figure()
colormap(mymap("rainbow"))
% colormap(slanCM('haline'))
som_show(sMap,'comp','all','norm','d','footnote','')   % 显示全部的特征
%som_show(sMap,'compi',[1],'norm','d')   % 显示部分特征值
%--------绘制各竞争层投影情况---------
figure()
% colormap('Lines')%运行colormapeditor可选择不同colormap
colormap(mymap("rainbow"))
h = som_hits(sMap,sD);     % 每个竞争层节点投中的样本数
som_show(sMap,'umat','all','empty','Labels','footnote','')
som_show_add('hit',h,'MarkerColor','m','Subplot',2)
%-----------------------------
[Pd,V,me] = pcaproj(sD.data,2);      % 数据降维
Pm = pcaproj(sMap.codebook,V,me);    % (竞争层)原型向量映射
U = som_umat(sMap);                  % 获取SOM的U矩阵
Um = U(1:2:size(U,1),1:2:size(U,2)); % 获取各个竞争层节点距离矩阵
%% ===============================kmeans===========================
Code = som_colorcode(Pm);  % 颜色编码
hits = som_hits(sMap,sD);  % hits
max_cluster = 12;
%--------DBI系数------
% DBI越小越好
% rng('default')
eva = evalclusters(sMap.codebook,'kmeans','DaviesBouldin','KList',2:max_cluster);
value = eva.CriterionValues;
figure()
plot(2:max_cluster,value,'r-','LineWidth',1.5);
xlabel('聚类数');
ylabel('DBI指数');
title('不同聚类数DBI情况');
grid on
box on
%---------自动选取最优类别----------------
[~,besti] = min(value);
besti = besti+1;
besti = 4;
[idx,Center0] = kmeans(sMap.codebook,besti);
Bmus = som_bmus(sMap,sD);   % 获取每个样本的最佳匹配单元(标签)
% [c,p,err,ind] = kmeans_clusters(sMap,max_cluster);     % kmeans聚类
%--------聚类--------
Code = som_colorcode(Pm);  % 颜色编码
hits = som_hits(sMap,sD);  % hits
max_cluster = 10;
Bmus = som_bmus(sMap,sD);   % 获取每个样本的最佳匹配单元(标签)
[c,p,err,ind] = kmeans_clusters(sMap,max_cluster);     % kmeans聚类
%-------------------------
figure()
%这里设置聚类数，可根据样品种类数修改。
% besti =4;
% som_show(sMap,'color',{p{besti},sprintf('聚类数：%d',besti)}); % 可视化
som_show(sMap,'color',{idx,sprintf('聚类数：%d',besti)},'footnote',''); % 可视化
colormap(autumn(besti))
som_recolorbar
% Class = p{besti};
Class = idx;
Y = [];
for ii = 1:1:size(X,1)
    best_match_unit = Bmus(ii,1);
    Y(ii,1) = Class(best_match_unit,1);
end
colorbar
colormap(hsv)
%----------------------------------
xlswrite('样本聚类结果.xlsx',Y);
%% =============================统计标签============================
%---------标签标号-----------
Cla = cell(1,1);
Cla(1,1) = Label(1,1);
Cla_num = [1];
for i = 2:1:length(Label)
    Bit = 0;
    for j = 1:1:length(Cla)
        if strcmp(Cla{j,1},Label{i,1})
            Cla_num = [Cla_num;j];
            Bit = 1;
            break;
        end
    end
    if Bit == 0
        Cla = [Cla;Label(i,1)];
        Cla_num = [Cla_num;length(unique(Cla_num))+1];
    end
end
%---------统计频次,构造标签---------
Label_fre = cell(MapNum,max(hits));
for i = 1:1:MapNum
    tempind = find(Bmus==i);
    tempnum = Cla_num(tempind,:);
    for j = 1:1:length(tempind)
        Label_fre{i,j} = Cla{tempnum(j),1};
    end
end
% sMap.labels = Label_fre;
NewLabel_fre = num2cell(hits);
sMap.labels = num2cell(hits);
%----------画图--------------
hold on
% figure()
%set(gcf,'color','w');
som_cplane(sMap,'none')
hold on
som_grid(sMap,'Label',sMap.labels,'Labelsize',8,...
	 'Line','none','Marker','none','Labelcolor','k');
set(gcf,'color','w');
hold off
colorbar
colormap(autumn)
%% =============================雷达图=============================
figure()
MaxC = sum(Center0);
Center = Center0./repmat(MaxC,besti,1);
RC = radarChart(Center);
RC.PropName = FeaName;
ClassName = [];
for i = 1:1:besti
    ClassName = [ClassName,{['类别',num2str(i)]}];
end
RC.ClassName = ClassName;
RC=RC.draw();
RC.legend();
%% ==============================移除路径===========================
rmpath(genpath(pwd));
