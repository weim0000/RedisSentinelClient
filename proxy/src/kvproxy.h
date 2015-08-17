#ifndef KVPROXY_MAIN_H
#define KVPROXY_MAIN_H

#include "version.h"
#include "serv.h"
#include "log.h"
#include "conn_pool.h"
#include "config.h"
#include "extension.h"
#include "util.h"
#include "hash.h"
#include <sys/types.h>
#include <sys/stat.h>

#include <pthread.h>
#include <set>
#include <vector>
#include <queue>
#include <list>
#include <map>
#include <array>
#include <limits.h>

#include "RedisClient.h"

using namespace bfd::redis;

using namespace std;

#define FAST_BUFF_SIZE 102400
#define TIMEOUT 100000
#define ST_LIMIT 2100000000
#define ASYNC_SIZE 50000
#define MAX_PACKET 1
#define FAILOVER_THRESHOLD 10
#define FAILOVER_INTERVAL 10

typedef map<uint32_t, req_ptr_list_t> req_group_t;
typedef map<uint32_t, comm_list_t> req_group_async_t;

class KvProxy : public Server{
private:

	//从配置文件读取sentinel地址
	std::string m_sentinelAddr;
    //host list. specify a number of aliases for each host.
    //the key is alias index , the value is pair, host and port
    map<uint32_t, pair<string,uint32_t> > host_alias;
    //the key is alias index, the value is a pair, index and weight
    map<uint32_t, pair<uint32_t, uint32_t> > host_infos;
    //the key is alias index, the value is bool. true is offline
    map<uint32_t, bool> host_offline;
    //default hosts
    set<uint32_t> hosts_default;
    //read hosts
    set<uint32_t> hosts_read;
    //backup hosts
    set<uint32_t> hosts_backup;

    Extension ext;
    ext_version_t ptr_ext_version;
    parse_req_t ptr_parse_req;
    create_req_t ptr_create_req;
    create_req_async_t ptr_create_req_async;
    parse_resp_t ptr_parse_resp;
    create_resp_t ptr_create_resp;
   
    ConnPool *conn_pool;
    ConsistentHash hash;
    ConsistentHash hash_backup;
    ConsistentHash hash_read;
    
    int connect_timeout;
    int send_timeout;
    int recv_timeout;
    int thread_count;
    int max_packet;
    int failover_threshold;
    int failover_interval;
    int async_size;
    string sync_str;
    bool cpu_affinity;    

    map<uint32_t, int> position;
    map<uint32_t, req_list_t> req_list_data;
    map<uint32_t, void *> req_buf;
    map<uint32_t, int> req_buf_size;
    map<uint32_t, int> req_buf_len;
    map<uint32_t, void *> resp_buf;
    map<uint32_t, int> resp_buf_size;
    map<uint32_t, int> resp_buf_len;
    map<uint32_t, void *> backend_buf;
    map<uint32_t, int> backend_buf_size;
    map<uint32_t, int> backend_buf_len;
    map<uint32_t, void *> client_buf;
    map<uint32_t, int> client_buf_size;
    map<uint32_t, int> client_buf_len;
    
    uint32_t st_req;
    int32_t st_conn;
    uint32_t st_limit;
    map<uint32_t, uint32_t> st_cont_fail;
    map<uint32_t, uint32_t> st_fail;

    static bool is_async;
    pthread_t th_async;
    pthread_t th_check_health;

	/**
	 * @brief Get thread-local RedisClient pointer.
	 */
	RedisClient& GetRedisClient();


    uint32_t setHostAlias(string host, uint32_t port);

    string getStatus();

protected:
    void readEvent(Conn *conn);
    void writeEvent(Conn *conn);
    void connectionEvent(Conn *conn);
    void closeEvent(Conn *conn, short events);

    std::string ReplyToString(const Reply& reply);
    std::string VectorToString(const std::vector<std::string>& values);
    string RedisCommand(vector<string>& command);
    void convertStr(std::string &str);

public:
    queue<req_group_async_t> async_req;
    pthread_mutex_t async_req_lock;

    KvProxy(int count, bool cpu_affinity);
    ~KvProxy();
  
    static void quitCb(int sig, short events, void *data);
    static void timeOutCb(int id, int short events, void *data);
    void setHosts(string type, string ext_name, uint32_t thread_count);
    int getThreadCount();
    map<uint32_t, pair<string,uint32_t> > getHostAlias();
    map<uint32_t, bool> getHostOffline();
    ConnPool * getConnPool();
    void countFail(bool is_fail, uint32_t alias_index);
    int getFailOverInterval();
    int getFailOverThreshold();
    map<uint32_t, uint32_t> getStContFail();
    void createCheckHealthThread();
    void initVar();
    bool failover(uint32_t alias_index, bool is_del);
};

string get_conf(string section, string key);

#endif
