function G = treeGeneration(spaceDimensions, perfPosition, Qperf, Pperf, Pterm, Nterm, Lmin, Lmax)
rng(1);
% ----------------------------------
% Generates a graph object representing a vascular tree
% Inputs:
% - spaceDimensions = 1x3 vector, size of the target space (m), e.g. [250, 250, 750]*1e-6
% - perfPosition = 1x3 vector, position of the perfusion point in the target space (m), e.g. [125,125,750]*1e-6
% - Qperf = scalar, initial perfusion flux (m/h/kg)
% - Pperf = scalar, initial perfusion pressure (mmHg)
% - Pterm = scalar, terminal perfusion pressure (mmHg)
% - Nterm = scalar, desired number of teminal nodes
% - Lmin = minimal distance between a node and a branch (m), e.g. 1e-6
% Outputs:
% - G = graph object, nodes represent the tree bifurcations, edges
% represent the branches
% Node properties : Name, Coord, parentNode, childrenNodes, isTermNode
% Edge properties : EndNodes, Name, r, Q, R, R_star, P, L, middle
% ----------------------------------
warning('off');
%% Hardcoded parameters
% initiate a max number of tries to place a new point to avoid infinite loops
maxTries = 1000;
visc = 0.036; % 36mPa.sec
% number of closest branches to consider when placing a new node
nClosest = 1; % will be 5 or 10 in the future
%exponential decay of Lmin
exposant = 0.4;

%% Initiate graph
G = digraph;
Qterm = Qperf/Nterm; %Qperf = Nterm * Qterm
deltaP = Pperf-Pterm;

%% create perfusion node
G = addVascNode(G, perfPosition, 0, 'n0');
% G = addnode(G, 'n0');
% G.Nodes.Coord{1}=perfPosition;


%% add first terminal node and first edge

% we might need a function that gets a random point in a defined space
% here the point can be anywhere in the volume but that might not be true
% for further use
coord = createRandCoord(spaceDimensions);
G = addVascNode(G, coord);
% G = addnode(G, 'n1');
% G.Nodes.Coord{2}=coord;
G = addVascEdge(G, 'n0', 'n1', Qterm); %Qterm, so that after N terminal nodes we have Qperf
G = updateTree(G, 'n0-n1', visc, deltaP);
%% Loop over number of required terminal nodes
nTries = 0;
while (sum(G.Nodes.isTermNode) < Nterm && nTries <= maxTries)
    nTries = nTries+1;
    coord = createRandCoord(spaceDimensions);
    % Check if not too close from other nodes / branch (compare with  Lmin)
    % if trop près
    % continue % ends this while iteration and passes to the next
    %end
    
    N_actuel = sum(G.Nodes.isTermNode);
    closestBranchesIdx = WhosClose(G,coord,nClosest,Lmin,Lmax,N_actuel,exposant);
    if closestBranchesIdx == 0
        continue
    end
    
    % loop on these branches
    score = inf;
    for i = 1:numel(closestBranchesIdx)
        
        [tmpG, candidateNodeName] = addVascNode(G, coord);
        edgeName = tmpG.Edges.Name{closestBranchesIdx(i)};
        tmpG = branchNode(tmpG, edgeName, candidateNodeName, Qterm, visc, deltaP);
        tmpScore = costFunction(tmpG);
        if tmpScore < score
            bestG = tmpG;
            score = tmpScore;
        end
    end
    
    % There we should have found the best candidate, so we keep it
    G = bestG;
    
    
    % We successfully added a new node! Reset try counter and go for next
    % node
    nTries = 0;
end
end



