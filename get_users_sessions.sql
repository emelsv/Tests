select (dense_rank() over (order by s.login_name))%2 as l1
      , (dense_rank() over (partition by s.login_name order by s.session_id))%2 as l2
      , (dense_rank() over (partition by s.session_id order by c.connection_id))%2 as l3
      , (row_number () over (partition by s.session_id,c.connection_id order by r.request_id))%2 as l4
      , s.session_id
      , s.login_time
      , s.host_name
      , s.program_name
      , s.cpu_time as cpu_time
      , s.memory_usage*8 as memory_usage
      , s.total_scheduled_time as total_scheduled_time
      , s.total_elapsed_time as total_elapsed_time
      , s.last_request_end_time
      , s.reads, s.writes
      , s.login_name
      , s.nt_domain
      , s.nt_user_name
      , convert(char(100),c.connection_id) as connection_id
      , c.connect_time
      , c.num_reads
      , c.num_writes
      , c.last_read
      , c.last_write
      , c.client_net_address
      , c.client_tcp_port
      , c.session_id
      , convert(char(100),r.request_id) as request_id
      , r.start_time
      , r.command
      , r.open_transaction_count
      , r.open_resultset_count
      , r.percent_complete
      , r.estimated_completion_time
      , r.reads
      , r.writes
      , case when r.sql_handle is not null then (select top 1 SUBSTRING(t2.text, (r.statement_start_offset + 2) / 2, ( (case when r.statement_end_offset = -1 then ((len(convert(nvarchar(MAX),t2.text))) * 2) else r.statement_end_offset end)  - r.statement_start_offset) / 2) from sys.dm_exec_sql_text(r.sql_handle) t2 )
      else ''
      end  as sql_statement
from sys.dm_exec_sessions s
left outer join sys.dm_exec_connections c  on ( s.session_id = c.session_id )
left outer join sys.dm_exec_requests r  on ( r.session_id = c.session_id and r.connection_id = c.connection_id )
where s.is_user_process = 1
    and s.login_name = 'OZON\seemelyanov'
