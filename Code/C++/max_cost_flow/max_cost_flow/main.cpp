#include <cstdio>
#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <iostream>

struct CostFlow{
    static const int inf;
    //V for vertexes, E for edges(needn't to consider reverses), max value
    int V, E;
    int S, T;	//source, target and maxnumber, must be SET BEFORE START
    int pedge, *head, *dist, *last, *que;
    int flow, cost;	//flow and cost result
    bool *used;
    bool maxFlow;

    struct Edge{
        int ver, next, flow, cost;
        Edge(){}
        Edge(int _ver, int _next, int _flow, int _cost):
            ver(_ver), next(_next), flow(_flow), cost(_cost){}
    }*edge;

    CostFlow(int v, int e, int s, int t)
            :V(v), E(e), S(s), T(t), maxFlow(true){
        pedge = 1;
        flow = 0;
        cost = 0;
        head = new int[V + 11];
        dist = new int[V + 11];
        que = new int[V + 11];
        last = new int[V + 11];
        used = new bool[V + 11];
        edge = new Edge[E * 2 + 11];
        memset(head, 0, sizeof(int) * (V + 11));
        memset(last, 0, sizeof(int) * (V + 11));
        memset(used, 0, sizeof(bool) * (V + 11));
        memset(edge, 0, sizeof(Edge) * (E * 2 + 11));
    }

    ~CostFlow(){
        delete []head;
        delete []dist;
        delete []que;
        delete []last;
        delete []used;
        delete []edge;
    }

    void insert(int u, int v, int cost = 0, bool isPair = false, int flow = 1){
        //printf("u=%2d v=%2d p=%2d c=%d b=%d\n", u, v, cost, flow, int(isPair));
        edge[++pedge] = Edge(v, head[u], -flow, cost);
        head[u] = pedge;
        edge[++pedge] = Edge(u, head[v], -flow * isPair, -cost);
        head[v] = pedge;
    }

    void minit(int &a, int b){
        a = (a < b ? a : b);
    }

    int bfs(){
        int cl, op, cur, i;
        for(int i = 1; i <= V; i++)
            dist[i] = inf;
        last[S] = 0;
        dist[que[op = 1] = S] = 0;
        used[S] = true;
        for(cl = 1; cl <= op && cl <= V * V; used[cur] = false, cl++)
            for(cur = que[cl % V], i = head[cur]; i; i = edge[i].next)
                if(edge[i].flow && dist[edge[i].ver] > dist[cur] + edge[i].cost){
                    dist[edge[i].ver] = dist[cur] + edge[i].cost;
                    last[edge[i].ver] = i;
                    if(!used[edge[i].ver]){
                        used[edge[i].ver] = true;
                        que[(++op) % V] = edge[i].ver;
                    }
                }
        if(maxFlow && dist[T] == inf)	//minimal cost maximal flow
            return false;
        if(!maxFlow && dist[T] > 0)		//minimal cost feasible flow
            return false;
        int mi = inf;
        for(i = last[T]; i; i = last[edge[i ^ 1].ver])
            minit(mi, -edge[i].flow);
        for(i = last[T]; i; i = last[edge[i ^ 1].ver]){
            edge[i].flow += mi;
            edge[i ^ 1].flow -= mi;
        }
        flow += mi;
        cost += dist[T] * mi;
        return true;
    }

    ///to get mincost
    int solve(){
        while(bfs());
        return cost;
    }

    ///print code to draw this graph with graphviz
    void printGraph(){
        printf("digraph{\n");
        for(int i = 1; i <= V; i++)
            for(int j = head[i]; j; j = edge[j].next)
                if(edge[j].flow){
                    static char sp[111];
                    static char sc[111];
                    if(edge[j].cost == 0)
                        sprintf(sp, "");
                    else
                        sprintf(sp, "p=%d", edge[j].cost);

                    if(edge[j].flow == -1)
                        sprintf(sc, "");
                    else
                        sprintf(sc, "c=%d", -edge[j].flow);
                    printf("%2d->%2d[label=\"%s %s\"];\n", i, edge[j].ver, sp, sc);
                }
        printf("}\n");
    }
}*costFlow;

//Must be a number greater than the sum of capacities and cost
const int CostFlow::inf = 0x3F3F3F3F;

int n, m, s;

inline int v_i(int a){
    return a;
}

inline int v_o(int a){
    return a + n;
}

int main(){

    //Number of vertices, number of edges, size of the set of vertices which must be used.
    //!! Vertices in this graph must be numbered from 1 to n in integer.
    scanf("%d%d%d", &n, &m, &s);

    //Original source and target are also exit and entrance of "toll station"
    int original_source = n * 2 + 1;
    int original_target = n * 2 + 2;

    //Additional source and target are for lower-and-upper-bounded flow <- this english name is named promiscuously by me
    int additional_source = n * 2 + 3;
    int additional_target = n * 2 + 4;

    costFlow = new CostFlow(n * 2 + 4, n * 5 + m + 1, additional_source, additional_target);

    int *degrees = new int[n * 2 + 11];
    memset(degrees, 0, sizeof(int) * (n * 2 + 11));

    //Input all the original edges.
    for(int i = 0; i < m; i++){
        int u, v;
        scanf("%d%d", &u, &v);
        //To eliminate negative cycles, set every nagative edge full initially
        //To get the maximal cost minimal flow, we set each cost with its opposite number to translate to minimal cost minimal flow problem
        degrees[v_o(u)]++;
        degrees[v_i(v)]--;
        costFlow->cost -= 1;
        costFlow->insert(v_i(v), v_o(u), 1);
    }

    //Input all the vertices which must visit
    bool *must_use = new bool[n + 11];
    memset(must_use, 0, sizeof(bool) * (n + 11));
    for(int i = 0; i < s; i++){
        int u;
        scanf("%d", &u);
        must_use[u] = true;
    }

    //Insert edges to limit vertices
    for(int i = 1; i <= n; i++){
        //Every original vertex can be the start point of a path, as well as the end point
        costFlow->insert(original_source, v_i(i));
        costFlow->insert(v_o(i), original_target);
        if(must_use[i]){
            //If must use this vertex, lower bound = upper bound = 1
            degrees[v_i(i)]++;
            degrees[v_o(i)]--;
        }else
            //If not, lower bound = 0, upper bound = 1
            costFlow->insert(v_i(i), v_o(i));
    }

    //For vertex whose initial input flow not equal to its output flow, use additional source and target to solve
    for(int i = 1; i <= n * 2; i++)
        if(degrees[i] > 0)
            costFlow->insert(i, additional_target, 0, false, degrees[i]);
        else if(degrees[i] < 0)
            costFlow->insert(additional_source, i, 0, false, -degrees[i]);

    //Add and edge with infinite capacity to use "toll station" discretionarily
    int inf_edge = costFlow->pedge + 1;
    costFlow->insert(original_target, original_source, 0, false, CostFlow::inf);

    //To get a minimal cost feasible flow of original graph, get minimal cost maximal flow of this graph with additional source and target
    //This graph can be flowed fully if and only if the original graph has a feasible flow
    //This graph can be flowed fully definitely, since this origial graph has a special property
    costFlow->maxFlow = true;
    costFlow->solve();

    int flow = -costFlow->edge[inf_edge ^ 1].flow;
    //Delete the edge between "toll station"
    costFlow->edge[inf_edge].flow = 0;
    costFlow->edge[inf_edge ^ 1].flow = 0;
    costFlow->flow = 0;

    //Restore source and target from the addtional ones to "toll station"
    //To get the minimal flow, set target as source while source as target
    costFlow->S = original_target;
    costFlow->T = original_source;

    //Run cost flow algorithm again to get the minimal cost minimal flow
    costFlow->maxFlow = true;
    costFlow->solve();

    //printf("Mininum number of paths chosen is %d.\n", flow - costFlow->flow);
    printf("%d\n", flow - costFlow->flow);
    //printf("Maxinum number of edges used is %d.\n", -costFlow->cost);
    printf("%d\n", -costFlow->cost);

    //Calculate the paths and cycles
    //which is the next vertex of each vertex in the original graph
    int *next = new int[n + 11];
    bool *not_start = new bool[n + 11];
    memset(next, 0, sizeof(int) * (n + 11));
    memset(not_start, 0, sizeof(bool) * (n + 11));
    for(int i = 1; i <= n; i++)
        for(int j = costFlow->head[v_o(i)]; j; j = costFlow->edge[j].next)
            //If this is the positive edge in the flow and the edge is full
            if(costFlow->edge[j].flow == 0 && costFlow->edge[j].cost == -1){
                not_start[costFlow->edge[j].ver] = true;
                next[i] = costFlow->edge[j].ver;
                break;
            }

    //printf("Paths:\n");
    printf("\n");

    for(int i = 1; i <= n; i++){
        if(not_start[i])
            continue;
        if(next[i]){
            for(int j = i, tmp; j; tmp = j, j = next[j], next[tmp] = 0)
                printf("%d ", j);
            printf("\n");
        }else if(must_use[i])
            printf("%d\n", i);
    }
    //printf("Cycles:\n");
    printf("\n");
    for(int i = 1; i <= n; i++){
        if(next[i]){
            printf("%d ", i);
            for(int j = next[i], tmp; j != i; tmp = j, j = next[j], next[tmp] = 0)
                printf("%d ", j);
            printf("%d\n", i);
        }
    }
    delete[] next;

    delete costFlow;
    delete[] must_use;
    delete[] degrees;

    return 0;
}
