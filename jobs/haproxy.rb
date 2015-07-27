require 'net/http' # for polling API
require 'csv'      # for parsing API response
require 'yaml'     # for parsing config file
require 'json'     # for hash transform

config = YAML.load File.open("config.yml")
config = config[:haproxy]
config[:green] ||= "#96bf48"
config[:yellow] ||= "#E2CF6A"
config[:red] ||= "#C44435"

overall = Hash.new
overall[:sessions_prev] = 0
overall[:queue_prev] = 0


SCHEDULER.every '5s', first_in: '5s', allow_overlapping: false do |job|
  status = Hash.new
  overall[:up_count] = 0
  overall[:down_count] = 0
  overall[:down_hosts] = []
  overall[:total] = 0
  overall[:up_percent] = 0
  overall[:sessions] = 0
  overall[:queue] = 0
  overall[:color] = ''

  config[:instances].each { |label, instance|
    # parse the configured URI
    uri = URI.parse(instance + "/;csv")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme.eql? 'https'

    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth(config[:username], config[:password])
    response = http.request(request)

    status[label] = CSV.parse(response.body)
  }

  status.each do |instance, state|
    state.each do |row|
      pxname = row[0].downcase
      svname = row[1].downcase

      # Evaluate pxname include / excludes
      # both includes and excludes - must be in includes or not excluded
      if !config[:pxname_include].nil? and !config[:pxname_exclude].nil?
        next if !config[:pxname_include].include? pxname or config[:pxname_exclude].include? pxname

      # only includes - must be in includes array
      elsif !config[:pxname_include].nil? and config[:pxname_exclude].nil?
        next unless config[:pxname_include].include? pxname

      # only excludes - must not be in excludes array
      elsif config[:pxname_include].nil? and !config[:pxname_exclude].nil? 
        next if config[:pxname_exclude].include? pxname

      # if no includes or excludes - assume including everything and excluding nothing
      end

      # Evaluate svname include / excludes
      if !config[:svname_include].nil? and !config[:svname_exclude].nil?
        next if !config[:svname_include].include? svname or config[:svname_exclude].include? svname

      elsif !config[:svname_include].nil? and config[:svname_exclude].nil?
        next unless config[:svname_include].include? svname

      elsif config[:svname_include].nil? and !config[:svname_exclude].nil? 
        next if config[:svname_exclude].include? svname
      end

      # Not currently used - but nice to have the mapping
      #unless overall.include? instance
      #  overall[instance] = {}
      #end

      #unless overall[instance].include? pxname
      #  overall[instance] = overall[instance].merge({ pxname => {} })
      #end

      # Builds a hash containing all the includes services keyed by pxname.svname
      #overall[instance][pxname] = overall[instance][pxname].merge({ svname => {
      #  "qcur" => row[2],
      #  "qmax" => row[3],
      #  "scur" => row[4],
      #  "smax" => row[5],
      #  "slim" => row[6],
      #  "stot" => row[7],
      #  "bin" => row[8],
      #  "bout" => row[9],
      #  "dreq" => row[10],
      #  "dresp" => row[11],
      #  "ereq" => row[12],
      #  "econ" => row[13],
      #  "eresp" => row[14],
      #  "wretr" => row[15],
      #  "wredis" => row[16],
      #  "status" => row[17],
      #  "weight" => row[18],
      #  "act" => row[19],
      #  "bck" => row[20],
      #  "chkfail" => row[21],
      #  "chkdown" => row[22],
      #  "lastchg" => row[23],
      #  "downtime" => row[24],
      #  "qlimit" => row[25],
      #  "pid" => row[26],
      #  "iid" => row[27],
      #  "sid" => row[28],
      #  "throttle" => row[29],
      #  "lbtot" => row[30],
      #  "tracked" => row[31],
      #  "type" => row[32],
      #  "rate" => row[33],
      #  "rate_lim" => row[34],
      #  "rate_max" => row[35],
      #  "check_status" => row[36],
      #  "check_code" => row[37],
      #  "check_duration" => row[38],
      #  "hrsp_1xx" => row[39],
      #  "hrsp_30xx" => row[40],
      #  "hrsp_3xx" => row[41],
      #  "hrsp_4xx" => row[42],
      #  "hrsp_5xx" => row[43],
      #  "hrsp_other" => row[44],
      #  "hanafail" => row[45],
      #  "req_rate" => row[46],
      #  "req_rate_max" => row[47],
      #  "req_tot" => row[48],
      #  "cli_abrt" => row[49],
      #  "srv_abrt" => row[50],
      #  "comp_in" => row[51],
      #  "comp_out" => row[52],
      #  "comp_byp" => row[53],
      #  "comp_rsp" => row[54],
      #  "lastsess" => row[55],
      #  "last_chk" => row[56],
      #  "last_agt" => row[57],
      #  "qtime" => row[58],
      #  "ctime" => row[59],
      #  "rtime" => row[60],
      #  "ttime" => row[61],
      #}})

      overall[:total] = overall[:total] + 1
      overall[:sessions] = overall[:sessions] + row[4].to_i
      overall[:queue] = overall[:queue] + row[2].to_i

      if row[17].downcase == 'up'
        overall[:up_count] = overall[:up_count] + 1
      else
        overall[:down_count] = overall[:down_count] + 1

        overall[:down_hosts] = overall[:down_hosts].push({
          label: instance,
          pxname: pxname,
          svname: svname,
          status: row[17],
          downtime: row[23],
          sessions: row[4],
          queue: row[2],
        })
      end
    end
  end

  overall[:up_percent] = (overall[:up_count].to_f / overall[:total].to_f * 100.0).floor

  if overall[:up_percent] <= config[:critical]
    overall[:color] = config[:red]
  elsif overall[:up_percent] <= config[:warning]
    overall[:color] = config[:yellow]
  else
    overall[:color] = config[:green]
  end

  send_event("haproxy-percent", { value: overall[:up_percent], color: overall[:color] })
  send_event("haproxy-up", { current: overall[:up_count] })
  send_event("haproxy-down", { current: overall[:down_count] })
  send_event("haproxy-sessions", { current: overall[:sessions], last: overall[:sessions_prev] })
  send_event("haproxy-queue", { current: overall[:queue], last: overall[:queue_prev] })
  send_event("haproxy-down-hosts", hosts: overall[:down_hosts])

  overall[:sessions_prev] = overall[:sessions]
  overall[:queue_prev] = overall[:queue]
end
