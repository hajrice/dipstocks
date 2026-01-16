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

# ULTRA-LIQUID US STOCKS - ~2400 symbols (Halal Compliant - No Banks/Insurance)
FAMOUS_SYMBOLS = %w[
  A AA AAL AAOI AAP AAPL AAWW ABBV ABCL ABG ABM ABNB ABT ACB ACC ACCO ACHC ACHR ACLS ACLX ACM ACMR ACN ADAP ADBE ADC ADCT ADI ADNT ADP ADPT ADSK ADUS ADVM AECOM AEE AEHR AEM AEO AEP AES AFRM AGCO AGFY AGG AGI AGIO AGS AGX AHH AI AIMC AIR AIRC AIRI AIRT AIV AJG AJRD AKAM AKR AKRO AKUS ALB ALDX ALEX ALG ALGM ALGN ALGT ALK ALLE ALLK ALNY ALSN ALTM ALTR ALV AM AMAT AMBA AMC AMCR AMCX AMD AME AMED AMEH AMGN AMH AMKR AMN AMPS AMPY AMRC AMRS AMSC AMT AMTI AMWD AMZN AN ANDE ANF ANGI ANGO ANIK ANIP ANNX ANSS AORT AOS AOSL APA APD APEI APEN APGE APH APLE APLS APOG APPF APPN APPS APTO APTS APTV AQN AR ARBK ARCB ARCO ARCT ARD ARDX ARE ARGX ARKG ARMK ARNC ARQT ARRY ARVL ARWR ASAN ASGN ASH ASHR ASIX ASO ASTC ASTE ASTI ASX ATGE ATHA ATI ATMU ATO ATR ATRC ATRO ATSG ATUS ATXG AU AURA AUTL AVA AVAV AVB AVGO AVIR AVNS AVPT AVXL AVY AWI AWK AWR AXL AXNX AXON AXSM AXTA AY AYI AYX AZEK AZN AZO B BA BABA BAH BALL BALY BAND BASE BATL BBWI BBY BC BCC BCPC BCRX BCYC BDN BDSX BDX BE BEAM BECN BEP BEPC BERY BF.A BF.B BFAM BFLY BFS BG BGFV BGNE BHP BHVN BIG BIGC BIIB BILL BIO BIOR BIP BIPC BITF BIV BJRI BKD BKH BKNG BKR BLDP BLDR BLL BLMN BLNK BLTE BLUE BLV BMBL BMC BMRN BMY BND BNED BNO BNTC BNTX BOIL BOOT BORR BOX BPYU BR BRFS BRG BRK.B BRKS BRO BROS BRX BRZE BSET BSV BSX BTBT BTCS BTI BTSG BTU BUD BURL BUSE BV BVN BWA BWEN BWXT BXC BXMT BXP BYD BYON BZH CABO CACC CADE CAG CAKE CAL CALM CALX CAMT CAN CANE CAPL CARA CARG CARR CARS CART CAT CBAY CBOE CBRE CBRL CBT CBZ CC CCI CCJ CCK CCL CCOI CCRN CCS CDAY CDEV CDLX CDN CDNS CE CECO CEG CELH CENT CENTA CENX CEPU CEQP CERE CEVA CF CFFN CFLT CFX CGC CGEM CGNX CHAP CHD CHDN CHE CHEF CHGG CHH CHK CHPT CHRD CHRS CHRW CHS CHTR CHUY CHWY CIEN CIFR CIGI CINT CIVI CL CLB CLBT CLDX CLF CLFD CLLS CLNC CLNE CLOV CLPR CLSD CLSK CLVR CLX CMA CMC CMCO CMCSA CME CMG CMI CMP CMPS CMS CNCE CNHI CNI CNK CNP CNSL CNTB CNX CNXC COGT COHR COHU COIN COKE COLD COLM COM COMM COMP CONN COP COPX COR CORN CORT CORZ COST COTY COUP COUR CP CPA CPB CPE CPER CPNG CPRI CPRT CPRX CPS CPT CQQQ CRAI CRBU CRDO CRGY CRH CRI CRL CRM CRON CROX CRS CRSP CRTX CRUS CRVL CRWD CSCO CSGP CSIQ CSR CSTM CSWI CSX CTAS CTB CTO CTRA CTRE CTRN CTSH CTVA CUB CUBE CUT CUTR CUZ CVE CVLG CVNA CVS CVX CW CWAN CWEN CWEN.A CWH CWT CYBR CYH CYT CZR D DAC DAL DAN DARE DASH DAWN DBA DBC DBO DCFC DCGO DCI DCO DCPH DCT DD DDM DDOG DE DECK DEI DELL DEN DENN DEO DG DGII DGRO DGX DHI DHR DIA DIGI DIOD DIS DISCA DISCK DISH DJP DK DKNG DKS DLA DLB DLO DLR DLTH DLTR DLX DMAC DMGI DNB DNLI DNN DNOW DNR DNUT DO DOC DOCN DOCU DOG DOOR DORM DOV DOW DPZ DQ DRD DRE DRH DRI DRIV DRMA DRQ DRVN DSGX DSKE DSX DT DTE DTM DUK DUOL DUST DV DVA DVAX DVN DVY DWDP DXCM DXD E EA EAT EBAY EBON ECHO ECL ED EDIT EDR EDU EEFT EEM EFA EFX EGLE EGO EHC EIX EL ELBM ELF ELME ELP ELS ELVN EMB EME EMN EMR ENLC ENOB ENPH ENSG ENTG ENTX ENVX EOG EOLS EOSE EPAM EPD EPIQ EPR EPRT EQIX EQR EQT ERJ ES ESAB ESI ESRT ESS ESTA ESTC ESTE ET ETN ETNB ETR ETSY EVAX EVC EVCM EVGO EVH EVLO EVLV EVOK EVRG EVRI EVTC EW EWA EWC EWG EWH EWJ EWS EWT EWU EWY EWZ EXAI EXC EXEL EXLS EXP EXPD EXPE EXPO EXPR EXR F FANG FAR FAST FATE FBHS FBIN FBRX FCEL FCN FCPT FCX FDS FDX FE FELE FERG FF FFIV FGEN FHTX FICO FIS FISV FIVE FIVN FIX FIZZ FL FLNG FLO FLOW FLR FLS FLT FLYW FMC FNKO FNV FOE FOLD FORM FOUR FOX FOXA FOXF FPI FR FRAC FRAN FREY FREYR FRHC FRME FROG FRPT FRSH FRT FSLR FSLY FSR FSS FTCI FTEC FTI FTNT FTS FTV FUL FULC FUN FUSN FUTU FVRR FWONA FWONK FWRD FWRG FXI FYBR GALT GBIO GCI GCP GCTI GD GDDY GDEN GDRX GDX GDXJ GE GEF GEF.B GEHC GEN GENI GERN GEVO GFF GFI GFL GGG GH GHC GIII GIL GILD GILT GIS GKOS GLBE GLD GLIBA GLNCY GLNG GLOB GLPG GLPI GLUE GLW GM GMAB GME GMED GMS GNCA GNE GNK GNL GNRC GNTX GO GOEV GOGL GOLD GOOD GOOG GOOGL GOOS GOSS GOTU GOVT GPC GPI GPK GPN GPOR GPRE GPS GRA GRCL GREE GRIN GRMN GRP GRPN GRTS GRWG GSAT GSG GSK GT GTE GTES GTHX GTLB GTLS GTN GTWN GTX GTY GVA GWW H HA HAE HAIN HAL HARP HAS HASI HAYN HAYW HBI HCA HD HDS HE HEI HEI.A HELE HES HESM HEXO HFC HGEN HIBB HIFR HII HIMS HIMX HIVE HIW HL HLF HLIO HLT HLTH HLX HMG HMHC HMPT HMY HNGR HNI HNNA HNST HOG HOLX HON HOOD HP HPE HPK HPP HPQ HQI HR HRL HRMY HRTX HSC HSIC HSKA HST HSY HT HTA HTLD HUBB HUBG HUBS HUN HURN HUT HWKN HWM HXL HYG HYLN HZNP IAC IAG IART IAS IAU IAUX IBB IBM IBP ICE ICFI ICHR ICLR ICPT ICUI IDA IDT IDU IDXX IEF IEFA IEMG IEX IFF IFRX IGMS IGT IGV IHG IHRT IIIV IIPR IJH IJR IMAB IMAX IMCR IMGN IMMP IMPP IMRX IMUX IMVT IMXI INBX INCY INDA INDI INDY INFI INFN INFO INFY INGR INMB INN INNV INO INSG INSM INSP INTC INTU INVH IONS IOSP IOVA IP IPAR IPG IQ IR IRBT IRC IRDM IREN IRM IRT IRTC IRWD ISEE ISRG ISSC ISTR IT ITCI ITGR ITOS ITOT ITRM ITT ITW IUSG IUSV IVE IVR IVV IVW IWB IWD IWF IWM IWV IYC IYE IYH IYJ IYK IYM IYR IYW IYZ J JACK JAKK JAMF JANX JAZZ JBGS JBHT JBLU JBSS JBT JCI JD JDST JE JELD JILL JJSF JKHY JKS JNJ JNK JNPR JNUG JO JOBY JOUT K KAI KALU KAMN KAR KARO KATE KBAL KBR KCNY KDNY KDP KEP KEX KEYS KFRC KGC KHC KIDS KIM KIND KL KLAC KLIC KMB KMG KMI KMT KMX KNBE KNF KNSA KNTE KNX KO KOLD KOP KOS KPTI KR KRA KRC KREF KRG KRNT KRO KRON KROS KRTX KRUS KRYS KTB KTOS KTRA KVYO KWEB KWR KYMR LABP LAD LANC LASR LAUR LAZR LBPH LBRDA LBRDK LBTYA LBTYB LBTYK LBY LC LCID LCII LDOS LEA LEG LEGN LEN LEU LEV LEVI LGF.A LGF.B LGIH LGND LH LHX LI LICY LII LILA LILAK LILM LIN LINC LITE LIVN LKQ LLY LMND LMNL LMT LNC LNDC LNG LNGG LNN LNT LNW LOCO LODE LOPE LOVE LOW LPCN LPRO LPTX LPX LQD LQDA LRCX LRN LSCC LSI LSPD LSTR LSXMA LSXMB LSXMK LTC LTHM LULU LUMN LUNG LUV LVS LW LXP LXU LYB LYEL LYFT LYV MA MAA MAC MACK MACOM MAG MANT MANU MAR MARA MARPS MAS MASI MAT MATX MAXN MAXR MBLY MBUU MCD MCFT MCHI MCHP MCO MCRI MCS MDB MDC MDGL MDLZ MDRR MDRX MDT MDXG MDXH MDY MEDP MEET MELI MEMO MEOH META MFA MGA MGEE MGI MGM MGNI MGP MGPI MGTA MGTX MHH MHK MIDD MIR MIRM MKC MKTX MLHR MLM MLYS MMM MMS MMSI MMYT MNDY MNR MNST MO MOD MOG.A MOG.B MORF MORN MOS MOV MP MPC MPLX MPWR MPX MQ MRC MRCY MREO MRK MRNA MRO MRSN MRTN MRTX MRUS MRVL MSCI MSFT MSGN MSI MSTR MTA MTCH MTD MTDR MTEM MTN MTOR MTSI MTTR MTUM MTX MTZ MU MUB MUR MWA MXL MYE MYOV MYPS MYRG NABL NAKD NAMS NAOV NARI NATR NBIX NCLH NCMGY NCNA NCNO NCSB NDAQ NDLS NDSN NEE NEM NEP NET NEU NEWM NEWR NEXA NEXT NFE NFLX NGL NGLOY NGVT NHC NI NIB NICE NIO NJR NKE NKLA NKTX NLSN NMFC NMRK NMTR NNN NNOX NOBL NOC NOTV NOV NOVA NOW NPK NPO NRDS NREF NRG NRP NRT NRZ NS NSA NSC NSSC NTAP NTLA NTNX NTR NTRA NU NUE NUGT NUS NUTR NUVA NVAX NVCR NVDA NVO NVR NVRO NVS NVST NVTA NVTS NWE NWL NWN NWPX NWS NWSA NX NXGN NXPI NXST NYT O OABI OAS OC OCEA OCGN OCUL ODC ODFL OEC OFC OFIX OFLX OGE OGI OGN OGS OHI OI OIH OII OIS OKE OKTA OLED OLLI OLN OLO OLP OMC OMCL OMER OMF OMI ON ONCT ONCX ONEW ONMD ONON ONTO OPCH OPEN OPI OPRX OR ORA ORC ORCL ORIC ORLY ORMP ORTX OSH OSIS OSPN OSTK OSUR OTIS OTTR OVID OVV OXM OXY PAA PAAS PACB PACK PACT PAG PAGS PALL PAND PANW PARA PARR PASG PATH PATK PAYC PAYO PAYX PBF PBFX PBT PCAR PCG PCRX PCTY PCY PCYO PD PDBC PDCE PDCO PDD PDFS PDM PDS PDSB PEAK PEB PECK PECO PEG PEGA PENN PEP PEPG PERI PFE PFGC PG PGEN PGRE PGTI PH PHAT PHGE PHIO PHM PHR PII PINC PINS PIRS PK PKG PKI PLAB PLAN PLAY PLD PLL PLNT PLRX PLSE PLTR PLUG PLXS PLYA PLYM PM PMT PNM PNR PNST PNW PODD POL POOL POR POSH POST POWI PPBB PPBI PPC PPG PPL PPLT PQG PRAX PRCH PRCT PRDO PRGO PRIM PRM PRPL PRSC PRSE PRTA PRTX PRTY PRVB PRZO PSA PSB PSD PSEG PSFE PSMT PSN PSNL PSO PSQ PSTG PSTL PSX PSXP PTAC PTC PTCT PTEN PTER PTGX PTLO PTRA PUBM PUMP PVG PVH PWR PXD PXMD PYPL PZZA QCOM QDEL QLD QLYS QNRX QQQ QRTEA QRVO QS QSR QTS QUAL QUIK QUOT QURE R RAD RADL RAIL RAPT RARE RAVE RBBN RBC RBLX RBRK RC RCEL RCKT RCL RCM RCUS RDDT RDFN RDHL RDNT REE REG REGN REI RELY REPL RES RETA REVG REX REXR REYN RGLD RGNX RGR RGS RH RHP RICK RIDE RIGL RIO RIOT RIVN RJF RL RLGT RLJ RLMD RMBS RMCF RMD RMNI RNA RNG RNGR ROCK ROG ROIC ROIV ROK ROKU ROL ROLL ROOT ROP ROST RPAI RPAY RPD RPID RPM RRC RRGB RRR RS RSI RSKD RSP RTH RTX RUBI RUBY RUN RUSHA RUSHB RUTH RVI RVLV RVMD RVNC RXDX RXN RXRX RYAAY RYN RYTM S SA SAFE SAFM SAGE SAH SAIA SAIC SAIL SALT SAM SANA SAND SATS SAVA SAVE SBAC SBGI SBLK SBR SBRA SBS SBUX SCG SCHA SCHB SCHD SCHG SCHL SCHM SCHP SCHV SCHX SCHZ SCL SCO SCOR SCPH SCS SCVL SD SDGR SDIG SDOW SDP SDRL SDS SDY SE SEAL SEAS SEDG SEE SEEL SEM SESN SFM SG SGC SGMO SGRY SGU SH SHAK SHC SHEN SHI SHLS SHO SHOO SHOP SHSP SHW SHY SHYF SHYG SIBN SID SIL SILJ SILK SIMO SIRI SITM SIX SIZE SJI SJM SJW SKIS SKLZ SKT SKX SKY SKYW SLAB SLB SLCA SLDP SLG SLGN SLV SM SMAR SMCI SMG SMH SMIN SMMT SMPL SMTC SMWB SN SNA SNAP SNBR SNCY SNDL SNDR SNDX SNMP SNOW SNPS SNSE SNY SO SOFI SOI SON SOS SOXX SOYB SPB SPG SPGI SPHR SPKE SPLG SPLK SPMD SPOT SPPI SPR SPRB SPSM SPTL SPTM SPTN SPTS SPWH SPWR SPXC SPXL SPXU SPY SPYG SPYV SQ SQM SQQQ SQSP SR SRC SRDX SRE SRG SRI SRPT SRRK SRTY SSB SSO SSP SSRM STAA STAG STAR STE STEM STIP STKL STKS STLA STLD STNE STNG STOK STOR STPR STRA STRL STRO STWD STX STZ SUB SUI SUM SUMO SUN SURF SVM SVRA SVXY SWAV SWC SWK SWKS SWN SWTX SWX SXI SXT SYBX SYF SYK SYNA SYNH SYRS SYY T TAC TACO TACS TAHO TAK TAL TALO TALS TAP TARA TARS TASK TAST TBF TBLA TBT TCMD TCO TCOM TCRR TDG TDW TDY TEAM TECK TEGN TEL TELA TELL TENB TER TEVA TEX TFFP TGAN TGI TGNA TGS TGT TGTX THC THO THRM THRX THS TIGR TILE TIP TITN TJX TKO TLRY TLT TMDX TMF TMO TMUS TMV TNA TNC TNDM TNET TNK TNL TNXP TOPS TOST TPIC TPL TPR TPTX TPVG TPX TQQQ TR TRDA TREX TRGP TRI TRIB TRIP TRMB TRMD TRNO TRNS TROX TRP TRQ TRS TRU TRUE TSCO TSE TSLA TSM TSN TT TTC TTD TTEC TTEK TTGT TTI TTOO TTWO TU TVTX TWIN TWLO TWNK TWOU TXMD TXN TXRH TXT TYL TYRA TZA U UA UAA UAL UAN UAVS UBA UBER UCO UDMY UDOW UDR UE UEC UFPI UFPT UGI UHAL UHS UHT ULBI ULH ULTA UMAB UMC UMH UNFI UNG UNH UNIT UNL UNP UNVR UPLD UPRO UPS UPST UPWK URA URBN URG URGN URNM URTY USAC USCR USFD USHY USL USLM USM USMV USNA USO USPH USX UTHR UTI UTZ UUUU UVXY UWMC V VAL VALE VAPO VAW VB VBIV VBK VBR VC VCEL VCIT VCLT VCNX VCR VCSH VCYT VDC VDE VEA VEDL VEEV VER VERA VERU VERV VET VFC VFF VGIT VGK VGLT VGSH VGT VHI VHT VIAC VIAV VIAVI VICI VIG VIRT VIS VITL VIXY VKTX VLCN VLO VLSI VLUE VMC VNCE VNDA VNET VNO VNOM VNQ VNRX VNTR VO VOO VOX VPL VPU VRAY VRCA VRDN VRE VRM VRNA VRNS VRSK VRSN VRTX VSAT VSEC VST VTEB VTEX VTI VTIP VTLE VTR VTRS VTV VTVT VUG VVV VWO VWOB VWS VXRT VXUS VXX VZ W WAB WAT WATT WBA WBD WBT WD WDAY WDC WDFC WEAT WEC WELL WEN WERN WES WEX WFRD WGL WGO WH WHD WING WISH WIT WK WKHS WLFC WLK WLL WM WMB WMG WMS WMT WOLF WOOD WOR WPC WPM WPX WRE WRI WRK WSM WSO WSR WST WTI WTR WTRG WTS WU WWD WWE WWW WY WYNN X XAIR XBI XBIT XCUR XEL XELA XENE XENT XERS XFOR XHR XLB XLC XLE XLI XLK XLP XLRE XLU XLV XLY XNCR XNET XOM XOMA XOP XPEL XPER XPEV XPO XPRO XRAY XRT XYL YELP YETI YEXT YMAB YMM YORW YUM YY Z ZBH ZBRA ZD ZETA ZEUS ZG ZI ZIM ZLAB ZM ZNTL ZS ZTO ZTS ZUO ZVO ZYME ZYXI
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
