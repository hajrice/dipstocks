#!/usr/bin/env ruby
# DIPMYASS.COM - Dip Recovery Scanner
# Run: ruby app.rb
# Then visit: http://localhost:4567

require "sinatra"
require "net/http"
require "json"
require "uri"

set :bind, '0.0.0.0'
set :port, ENV['PORT'] || 4567

# ULTRA-LIQUID ONLY - stuff you can move $2M+ without blinking
FAMOUS_SYMBOLS = %w[
  GLD SLV USO UNG DBA DBC IAU PPLT PALL
  SPY QQQ DIA IWM VOO VTI IVV MDY IJH IJR
  XLK XLF XLE XLV XLI XLP XLY XLB XLU XLRE
  TLT IEF SHY LQD HYG AGG BND TIP
  AAPL MSFT GOOGL GOOG AMZN NVDA META TSLA
  JPM BAC WFC GS MS C BLK
  JNJ PFE MRK ABBV LLY UNH
  XOM CVX COP SLB OXY
  V MA AXP PYPL
  HD LOW COST WMT TGT
  BA CAT DE MMM HON GE
  KO PEP MCD SBUX
  INTC AMD MU QCOM AVGO TXN AMAT LRCX
  DIS NFLX CMCSA
  T VZ TMUS
  BRK.B
]

TOP_N = 20
MIN_MARKET_CAP = 10_000_000_000 # $10B minimum

def fetch_quote(symbol)
  url = "https://query1.finance.yahoo.com/v8/finance/chart/#{symbol}?interval=1m&range=1d"
  uri = URI(url)
  
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 5
  http.read_timeout = 5
  
  request = Net::HTTP::Get.new(uri)
  request["User-Agent"] = "Mozilla/5.0"
  
  response = http.request(request)
  return nil unless response.is_a?(Net::HTTPSuccess)
  
  data = JSON.parse(response.body)
  result = data.dig("chart", "result", 0)
  return nil unless result
  
  meta = result["meta"]
  quotes = result.dig("indicators", "quote", 0)
  return nil unless meta && quotes
  
  closes = (quotes["close"] || []).compact
  return nil if closes.size < 10
  
  current = meta["regularMarketPrice"] || closes.last
  prev_close = meta["previousClose"] || meta["chartPreviousClose"]
  day_high = meta["regularMarketDayHigh"] || closes.max
  day_low = meta["regularMarketDayLow"] || closes.min
  
  return nil unless current && prev_close && prev_close > 0
  
  day_change = ((current - prev_close) / prev_close) * 100
  open_price = meta["regularMarketOpen"] || closes.first
  dip_from_open = ((day_low - open_price) / open_price) * 100
  recovery_from_low = ((current - day_low) / day_low) * 100
  
  recent_avg = closes[-5..-1].sum / 5.0
  earlier_avg = closes[-10..-6].sum / 5.0
  momentum = ((recent_avg - earlier_avg) / earlier_avg) * 100
  
  range = day_high - day_low
  position_in_range = range > 0 ? ((current - day_low) / range) * 100 : 50
  
  {
    symbol: symbol,
    price: current,
    day_change: day_change.round(2),
    dip_from_open: dip_from_open.round(2),
    recovery: recovery_from_low.round(2),
    momentum: momentum.round(3),
    range_position: position_in_range.round(0),
    star: (dip_from_open < -0.5 && momentum > 0.02 && position_in_range < 60)
  }
rescue => e
  nil
end

def fetch_top_movers
  movers = []
  
  %w[gainers losers].each do |type|
    url = "https://query1.finance.yahoo.com/v1/finance/screener/predefined/saved?scrIds=day_#{type}&count=50"
    uri = URI(url)
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 10
    
    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = "Mozilla/5.0"
    
    begin
      response = http.request(request)
      next unless response.is_a?(Net::HTTPSuccess)
      
      data = JSON.parse(response.body)
      quotes = data.dig("finance", "result", 0, "quotes") || []
      
      quotes.each do |q|
        market_cap = q["marketCap"]
        next unless market_cap && market_cap >= MIN_MARKET_CAP
        
        movers << {
          symbol: q["symbol"],
          name: q["shortName"] || q["longName"] || q["symbol"],
          price: q["regularMarketPrice"],
          day_change: q["regularMarketChangePercent"]&.round(2),
          market_cap: market_cap,
          volume: q["regularMarketVolume"],
          type: type == "gainers" ? :gainer : :loser
        }
      end
    rescue => e
      next
    end
  end
  
  movers
end

def scan_famous_stocks
  results = []
  
  threads = FAMOUS_SYMBOLS.map do |sym|
    Thread.new { fetch_quote(sym) }
  end
  
  results = threads.map(&:value).compact
  
  dip_recoveries = results.select do |r|
    r[:dip_from_open] < -0.1 &&
    r[:momentum] > 0 &&
    r[:recovery] > 0.05 &&
    r[:range_position] < 85
  end
  
  dip_recoveries.sort_by { |r| -r[:momentum] }.first(TOP_N)
end

def scan_top_movers
  movers = fetch_top_movers
  return { gainers: [], losers: [], dip_recoveries: [] } if movers.empty?
  
  # Get detailed dip/recovery data for each mover
  symbols = movers.map { |m| m[:symbol] }
  
  threads = symbols.map do |sym|
    Thread.new { [sym, fetch_quote(sym)] }
  end
  
  quote_data = threads.map(&:value).to_h
  
  # Merge mover data with quote data
  enriched = movers.map do |m|
    quote = quote_data[m[:symbol]]
    next m unless quote
    
    m.merge(
      dip_from_open: quote[:dip_from_open],
      momentum: quote[:momentum],
      range_position: quote[:range_position],
      recovery: quote[:recovery],
      star: quote[:star]
    )
  end.compact
  
  # Filter for dip recovery pattern among movers
  dip_recoveries = enriched.select do |r|
    r[:dip_from_open] && r[:dip_from_open] < -0.1 &&
    r[:momentum] && r[:momentum] > 0 &&
    r[:recovery] && r[:recovery] > 0.05 &&
    r[:range_position] && r[:range_position] < 85
  end
  
  {
    gainers: enriched.select { |m| m[:type] == :gainer }.sort_by { |m| -(m[:day_change] || 0) }.first(TOP_N),
    losers: enriched.select { |m| m[:type] == :loser }.sort_by { |m| m[:day_change] || 0 }.first(TOP_N),
    dip_recoveries: dip_recoveries.sort_by { |r| -(r[:momentum] || 0) }.first(TOP_N)
  }
end

get '/' do
  @famous = scan_famous_stocks
  @movers = scan_top_movers
  @scan_time = Time.now.strftime('%H:%M:%S')
  erb :index
end

get '/api' do
  content_type :json
  {
    famous_stocks: scan_famous_stocks,
    top_movers: scan_top_movers,
    scanned_at: Time.now.iso8601
  }.to_json
end

helpers do
  def format_market_cap(cap)
    return "N/A" unless cap
    if cap >= 1_000_000_000_000
      "$#{(cap / 1_000_000_000_000.0).round(2)}T"
    elsif cap >= 1_000_000_000
      "$#{(cap / 1_000_000_000.0).round(1)}B"
    else
      "$#{(cap / 1_000_000.0).round(0)}M"
    end
  end
end

__END__

@@index
<!DOCTYPE html>
<html>
<head>
  <title>DipMyAss.com - Catch the Bounce</title>
  <meta http-equiv="refresh" content="30">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    
    @keyframes snow {
      0% { transform: translateY(-10px) rotate(0deg); opacity: 0; }
      10% { opacity: 1; }
      90% { opacity: 1; }
      100% { transform: translateY(100vh) rotate(360deg); opacity: 0; }
    }
    
    @keyframes twinkle {
      0%, 100% { opacity: 0.3; }
      50% { opacity: 1; }
    }
    
    body { 
      font-family: -apple-system, BlinkMacSystemFont, 'SF Mono', Consolas, monospace;
      background: #0a0f0a; 
      color: #e0e0e0;
      padding: 20px;
      line-height: 1.5;
      position: relative;
      min-height: 100vh;
      overflow-x: hidden;
    }
    
    /* Snowflakes */
    .snowflake {
      position: fixed;
      top: -10px;
      color: #fff;
      font-size: 14px;
      opacity: 0;
      pointer-events: none;
      z-index: 1000;
      animation: snow linear infinite;
    }
    .snowflake:nth-child(1) { left: 5%; animation-duration: 15s; animation-delay: 0s; }
    .snowflake:nth-child(2) { left: 15%; animation-duration: 12s; animation-delay: 2s; font-size: 10px; }
    .snowflake:nth-child(3) { left: 25%; animation-duration: 18s; animation-delay: 4s; }
    .snowflake:nth-child(4) { left: 35%; animation-duration: 14s; animation-delay: 1s; font-size: 8px; }
    .snowflake:nth-child(5) { left: 45%; animation-duration: 16s; animation-delay: 3s; }
    .snowflake:nth-child(6) { left: 55%; animation-duration: 13s; animation-delay: 5s; font-size: 12px; }
    .snowflake:nth-child(7) { left: 65%; animation-duration: 17s; animation-delay: 2s; }
    .snowflake:nth-child(8) { left: 75%; animation-duration: 11s; animation-delay: 4s; font-size: 10px; }
    .snowflake:nth-child(9) { left: 85%; animation-duration: 15s; animation-delay: 1s; }
    .snowflake:nth-child(10) { left: 95%; animation-duration: 14s; animation-delay: 3s; font-size: 8px; }
    
    .container { max-width: 1200px; margin: 0 auto; position: relative; z-index: 1; }
    
    .header {
      text-align: center;
      margin-bottom: 40px;
      padding: 30px 0;
      border-bottom: 1px solid #1a2f1a;
      position: relative;
    }
    
    .header-lights {
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      height: 4px;
      background: repeating-linear-gradient(
        90deg,
        #c41e3a 0px, #c41e3a 20px,
        transparent 20px, transparent 30px,
        #228b22 30px, #228b22 50px,
        transparent 50px, transparent 60px
      );
      border-radius: 2px;
    }
    
    .header-lights::after {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      height: 4px;
      background: repeating-linear-gradient(
        90deg,
        rgba(255,255,255,0.5) 0px, rgba(255,255,255,0.5) 20px,
        transparent 20px, transparent 30px,
        rgba(255,255,255,0.5) 30px, rgba(255,255,255,0.5) 50px,
        transparent 50px, transparent 60px
      );
      animation: twinkle 1.5s ease-in-out infinite;
    }
    
    .logo-img {
      max-width: 280px;
      height: auto;
      margin-bottom: 10px;
    }
    
    .logo { 
      font-size: 42px; 
      font-weight: 800;
      margin-bottom: 8px;
    }
    .logo .dip { color: #c41e3a; }
    .logo .my { color: #228b22; }
    .logo .ass { color: #c41e3a; }
    
    .tagline {
      color: #888;
      font-size: 16px;
      font-weight: 400;
    }
    .tagline .accent { color: #228b22; }
    
    .meta { 
      display: flex; 
      justify-content: center;
      gap: 25px; 
      margin-top: 15px;
      font-size: 13px;
      color: #555;
    }
    .meta span::before {
      content: '🎄 ';
      font-size: 10px;
    }
    
    .section {
      margin-bottom: 50px;
    }
    .section-header {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-bottom: 20px;
    }
    .section-icon {
      font-size: 24px;
    }
    h2 { 
      color: #fff; 
      font-size: 20px; 
      font-weight: 600;
    }
    .section-desc {
      color: #666;
      font-size: 13px;
      margin-left: 36px;
      margin-top: -15px;
      margin-bottom: 20px;
    }
    
    .strategy {
      background: linear-gradient(135deg, #0f1a0f 0%, #1a0f0f 100%);
      border: 1px solid #1a2f1a;
      border-radius: 8px;
      padding: 15px 18px;
      margin-bottom: 20px;
      font-size: 13px;
    }
    .strategy span { color: #c41e3a; font-weight: 500; }
    
    table { 
      width: 100%; 
      border-collapse: collapse;
      font-size: 14px;
      background: #0a0f0a;
      border-radius: 8px;
      overflow: hidden;
      border: 1px solid #1a2f1a;
    }
    th { 
      text-align: left; 
      padding: 14px 12px;
      background: linear-gradient(180deg, #0f1a0f 0%, #0a0f0a 100%);
      border-bottom: 2px solid #1a2f1a;
      color: #666;
      font-weight: 500;
      font-size: 11px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    td { 
      padding: 12px;
      border-bottom: 1px solid #1a2f1a;
    }
    tr:hover { background: rgba(34, 139, 34, 0.1); }
    tr:last-child td { border-bottom: none; }
    
    .positive { color: #4ade80; }
    .negative { color: #f87171; }
    .star { color: #ffd700; }
    .symbol { 
      font-weight: 600; 
      color: #fff;
    }
    .name {
      color: #666;
      font-size: 12px;
      max-width: 200px;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    .price { color: #ccc; }
    .market-cap { color: #888; font-size: 12px; }
    
    .empty {
      text-align: center;
      padding: 50px 20px;
      color: #444;
      background: #0a0f0a;
      border-radius: 8px;
      border: 1px solid #1a2f1a;
    }
    .empty::before {
      content: '🎅';
      display: block;
      font-size: 40px;
      margin-bottom: 15px;
    }
    
    .tabs {
      display: flex;
      gap: 10px;
      margin-bottom: 20px;
    }
    .tab {
      padding: 10px 20px;
      background: #0f1a0f;
      border: 1px solid #1a2f1a;
      border-radius: 6px;
      color: #888;
      font-size: 13px;
      cursor: pointer;
      transition: all 0.2s;
    }
    .tab:hover { border-color: #228b22; color: #aaa; }
    .tab.active { 
      background: linear-gradient(135deg, #1a2f1a 0%, #2f1a1a 100%);
      border-color: #c41e3a; 
      color: #fff;
    }
    .tab-content { display: none; }
    .tab-content.active { display: block; }
    
    .legend {
      margin-top: 30px;
      padding: 18px;
      background: linear-gradient(135deg, #0f1a0f 0%, #1a0f0f 100%);
      border: 1px solid #1a2f1a;
      border-radius: 8px;
      font-size: 12px;
      color: #555;
    }
    .legend p { margin-bottom: 6px; }
    .legend p:last-child { margin-bottom: 0; }
    .legend .positive, .legend .negative, .legend .star { font-weight: 600; }
    
    .footer {
      text-align: center;
      margin-top: 40px;
      padding: 20px;
      color: #444;
      font-size: 12px;
    }
    .footer .tree { font-size: 24px; }
  </style>
</head>
<body>
  <!-- Snowflakes -->
  <div class="snowflake">❄</div>
  <div class="snowflake">❄</div>
  <div class="snowflake">❄</div>
  <div class="snowflake">❄</div>
  <div class="snowflake">❄</div>
  <div class="snowflake">❄</div>
  <div class="snowflake">❄</div>
  <div class="snowflake">❄</div>
  <div class="snowflake">❄</div>
  <div class="snowflake">❄</div>
  
  <div class="container">
    <div class="header">
      <div class="header-lights"></div>
      <img src="logo.jpeg" style="width:120px" />
      <div class="logo"><span class="dip">Dip</span><span class="my">My</span><span class="ass">Ass</span>.com</div>
      <p class="tagline">Catch the bounce. <span class="accent">Ride the recovery.</span> 🎁</p>
      <div class="meta">
        <span>Last scan: <%= @scan_time %></span>
        <span>Auto-refresh: 30s</span>
        <span>$10B+ market cap only</span>
      </div>
    </div>
    
    <!-- FAMOUS STOCKS SECTION -->
    <div class="section">
      <div class="section-header">
        <span class="section-icon">🎁</span>
        <h2>DipMyAss Famous Stocks</h2>
      </div>
      <p class="section-desc">Ultra-liquid assets (SPY, QQQ, mega-caps) showing dip recovery patterns</p>
      
      <div class="strategy">
        <span>Strategy:</span> Find famous stocks that DIPPED but are NOW recovering<br>
        <span>Filter:</span> Dipped from open + Positive momentum + Not at day high
      </div>
      
      <% if @famous.empty? %>
        <div class="empty">
          <p>No dip-recovery patterns in famous stocks right now.</p>
          <p>Market may be flat, closed, or no clear setups.</p>
        </div>
      <% else %>
        <table>
          <thead>
            <tr>
              <th>Symbol</th>
              <th>Price</th>
              <th>Day %</th>
              <th>Dip %</th>
              <th>Momentum</th>
              <th>Range</th>
            </tr>
          </thead>
          <tbody>
            <% @famous.each do |r| %>
              <tr>
                <td class="symbol">
                  <% if r[:star] %><span class="star">⭐ </span><% end %><%= r[:symbol] %>
                </td>
                <td class="price">$<%= sprintf('%.2f', r[:price]) %></td>
                <td class="<%= r[:day_change] >= 0 ? 'positive' : 'negative' %>">
                  <%= sprintf('%+.2f%%', r[:day_change]) %>
                </td>
                <td class="negative"><%= sprintf('%.2f%%', r[:dip_from_open]) %></td>
                <td class="positive"><%= sprintf('%+.3f%%', r[:momentum]) %></td>
                <td><%= r[:range_position].to_i %>%</td>
              </tr>
            <% end %>
          </tbody>
        </table>
      <% end %>
    </div>
    
    <!-- TOP MOVERS SECTION -->
    <div class="section">
      <div class="section-header">
        <span class="section-icon">🦌</span>
        <h2>DipMyAss Top Movers</h2>
      </div>
      <p class="section-desc">Today's biggest gainers & losers with $10B+ market cap</p>
      
      <div class="tabs">
        <div class="tab active" onclick="showTab('dip-recovery', this)">🎯 Dip Recoveries</div>
        <div class="tab" onclick="showTab('gainers', this)">🎅 Gainers</div>
        <div class="tab" onclick="showTab('losers', this)">☃️ Losers</div>
      </div>
      
      <!-- Dip Recovery Tab -->
      <div id="dip-recovery" class="tab-content active">
        <% if @movers[:dip_recoveries].empty? %>
          <div class="empty">
            <p>No dip-recovery patterns in top movers right now.</p>
          </div>
        <% else %>
          <table>
            <thead>
              <tr>
                <th>Symbol</th>
                <th>Name</th>
                <th>Price</th>
                <th>Day %</th>
                <th>Dip %</th>
                <th>Momentum</th>
                <th>Mkt Cap</th>
              </tr>
            </thead>
            <tbody>
              <% @movers[:dip_recoveries].each do |r| %>
                <tr>
                  <td class="symbol">
                    <% if r[:star] %><span class="star">⭐ </span><% end %><%= r[:symbol] %>
                  </td>
                  <td class="name"><%= r[:name] %></td>
                  <td class="price">$<%= sprintf('%.2f', r[:price] || 0) %></td>
                  <td class="<%= (r[:day_change] || 0) >= 0 ? 'positive' : 'negative' %>">
                    <%= sprintf('%+.2f%%', r[:day_change] || 0) %>
                  </td>
                  <td class="negative"><%= sprintf('%.2f%%', r[:dip_from_open] || 0) %></td>
                  <td class="positive"><%= sprintf('%+.3f%%', r[:momentum] || 0) %></td>
                  <td class="market-cap"><%= format_market_cap(r[:market_cap]) %></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        <% end %>
      </div>
      
      <!-- Gainers Tab -->
      <div id="gainers" class="tab-content">
        <% if @movers[:gainers].empty? %>
          <div class="empty"><p>No gainers data available.</p></div>
        <% else %>
          <table>
            <thead>
              <tr>
                <th>Symbol</th>
                <th>Name</th>
                <th>Price</th>
                <th>Day %</th>
                <th>Dip %</th>
                <th>Momentum</th>
                <th>Mkt Cap</th>
              </tr>
            </thead>
            <tbody>
              <% @movers[:gainers].each do |r| %>
                <tr>
                  <td class="symbol"><%= r[:symbol] %></td>
                  <td class="name"><%= r[:name] %></td>
                  <td class="price">$<%= sprintf('%.2f', r[:price] || 0) %></td>
                  <td class="positive"><%= sprintf('%+.2f%%', r[:day_change] || 0) %></td>
                  <td class="<%= (r[:dip_from_open] || 0) < 0 ? 'negative' : '' %>">
                    <%= sprintf('%.2f%%', r[:dip_from_open] || 0) %>
                  </td>
                  <td class="<%= (r[:momentum] || 0) > 0 ? 'positive' : 'negative' %>">
                    <%= sprintf('%+.3f%%', r[:momentum] || 0) %>
                  </td>
                  <td class="market-cap"><%= format_market_cap(r[:market_cap]) %></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        <% end %>
      </div>
      
      <!-- Losers Tab -->
      <div id="losers" class="tab-content">
        <% if @movers[:losers].empty? %>
          <div class="empty"><p>No losers data available.</p></div>
        <% else %>
          <table>
            <thead>
              <tr>
                <th>Symbol</th>
                <th>Name</th>
                <th>Price</th>
                <th>Day %</th>
                <th>Dip %</th>
                <th>Momentum</th>
                <th>Mkt Cap</th>
              </tr>
            </thead>
            <tbody>
              <% @movers[:losers].each do |r| %>
                <tr>
                  <td class="symbol">
                    <% if r[:star] %><span class="star">⭐ </span><% end %><%= r[:symbol] %>
                  </td>
                  <td class="name"><%= r[:name] %></td>
                  <td class="price">$<%= sprintf('%.2f', r[:price] || 0) %></td>
                  <td class="negative"><%= sprintf('%+.2f%%', r[:day_change] || 0) %></td>
                  <td class="<%= (r[:dip_from_open] || 0) < 0 ? 'negative' : '' %>">
                    <%= sprintf('%.2f%%', r[:dip_from_open] || 0) %>
                  </td>
                  <td class="<%= (r[:momentum] || 0) > 0 ? 'positive' : 'negative' %>">
                    <%= sprintf('%+.3f%%', r[:momentum] || 0) %>
                  </td>
                  <td class="market-cap"><%= format_market_cap(r[:market_cap]) %></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        <% end %>
      </div>
    </div>
    
    <div class="legend">
      <p><span class="positive">MOMENTUM</span> = Last 5 min trend vs prior 5 min (higher = faster recovery)</p>
      <p><span class="negative">DIP %</span> = How far it dropped from open (bigger dip = better setup)</p>
      <p>RANGE = Position in today's range (0%=low, 100%=high)</p>
      <p><span class="star">⭐</span> = Best setups: big dip + strong recovery + room to run</p>
      <p>Top Movers filtered to $10B+ market cap only</p>
    </div>
    
    <div class="footer">
      <div class="tree">🎄</div>
      <p>Buy the dip. 'Tis the season for gains.</p>
    </div>
  </div>
  
  <script>
    function showTab(tabId, el) {
      document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
      document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
      document.getElementById(tabId).classList.add('active');
      el.classList.add('active');
    }
  </script>
</body>
</html>
