class MunerisController < ApplicationController
  
  before_filter :authenticate_user!

  def dashboard

    @is_current_user = current_user == @user

    @activities = PublicActivity::Activity.order("created_at desc").where(owner_id: current_user.friends, owner_type: "User")

    @friends = current_user.friends 

    #------------------------------------ADMIN--------------------------------------

    if @current_user.admin?

      @users = User.select('id,familyname,address,locale,tariff,avatar_file_name').where(:admin => nil)

      @bills = Bill.select('id, consumption, value, date, service')

      tariffs = @users.map(&:tariff).uniq
      @userstariff = []

      locales = @users.map(&:locale).uniq
      @userscity = []

      services = @bills.map(&:service).uniq
      @billsservice = []

      @averagestariff = []
      tariffs.each do |tariff|
        users = @users.select{ |k,v| k[:tariff] == tariff}
        @averagestarifflista = []

        # services
        [1, 2, 3].each do |service|
          bills_total = users.map { |u| u.valor_total(service) }.inject(0, :+)
          if bills_total == 0
            bills_total =1
          end
          consumption = users.map { |u| u.valor(service) }.inject(0, :+)
          @averagestariff << { tariff: tariff, service: service , average: consumption / bills_total }
          @averagestarifflista << { service: service , average: consumption / bills_total }
        end

        @userstariff << { tariff: tariff, value: users.size, averages: @averagestarifflista }

      end

      @bartariff = LazyHighCharts::HighChart.new('column') do |f|
        if @current_user.admin == 1 
          f.series(:name=>'Energy',:data => @averagestariff.select{ |k,v| k[:service] == 1 }.collect { |e| e[:average]  } )
        elsif @current_user.admin == 2    
          f.series(:name=>'Water',:data=> @averagestariff.select{ |k,v| k[:service] == 2 }.collect { |e| e[:average]  } )
        elsif @current_user.admin == 3 
          f.series(:name=>'Gas',:data=> @averagestariff.select{ |k,v| k[:service] == 3 }.collect { |e| e[:average]  } )
        end
        f.xAxis({:categories => @userstariff.collect { |e| e[:tariff]} })  
        f.title({ :text=>"Average by Classification"})
        f.legend(enabled: false)
        f.options[:chart][:defaultSeriesType] = "column"
      end

      @averagescity = []
      locales.each do |locale|
        users = @users.select{ |k,v| k[:locale] == locale}
        @averagescitylista = []     

        [1, 2, 3].each do |service|
          bills_total = users.map { |u| u.valor_total(service) }.inject(0, :+)
          if bills_total == 0
            bills_total =1
          end
          consumption = users.map { |u| u.valor(service) }.inject(0, :+)
          @averagescity << { locale: locale, service: service , average: consumption / bills_total }
          @averagescitylista << {service: service , average: consumption / bills_total }
        end

        @userscity << { locale: locale.split(",").first, value: @users.select{ |k,v| k[:locale] == locale}.size, averages: @averagescitylista }

      end

      @barcity = LazyHighCharts::HighChart.new('column') do |f|
        if @current_user.admin == 1 
          f.series(:name=>'Energy',:data=> @averagescity.select{ |k,v| k[:service] == 1 }.collect { |e| e[:average]  } )
        elsif @current_user.admin == 2        
          f.series(:name=>'Water',:data=> @averagescity.select{ |k,v| k[:service] == 2 }.collect { |e| e[:average]  } )
        elsif @current_user.admin == 3 
          f.series(:name=>'Gas',:data=> @averagescity.select{ |k,v| k[:service] == 3 }.collect { |e| e[:average]  } )
        end
        f.xAxis({:categories => @userscity.collect { |e| e[:locale]} })    
        f.title({ :text=>"Average by city"})
        f.legend(enabled: false)
        f.options[:chart][:defaultSeriesType] = "column"
      end

      @bills_pie_total = []
      [1, 2, 3].each do |service|
        @averagestariff = []
        ['Residencial Estrato 1', 'Residencial Estrato 2', 'Residencial Estrato 3','Residencial Estrato 4', 'Residencial Estrato 5', 'Residencial Estrato 6',"Oficial Nivel I", "Oficial Nivel II", "Comercial Nivel I", "Comercial Nivel II"].each do |tariff|
          users = @users.select{ |k,v| k[:tariff] == tariff}

          @consumption = users.map { |u| u.valor(service) }.inject(0, :+)
          @averagestariff << { tariff: tariff, service: service , average: @consumption }
        end

        @tariffdivisor = @averagestariff.select{ |k,v| k[:service] == service }.collect{ |e| e[:average]  }.inject(0, :+)
        if @tariffdivisor == 0
         @tariffdivisor = 1
        end
        @bills_pie_total << {service: service, tariff: @averagestariff.select{ |k,v| k[:service] == service }.collect { |e| e[:tariff] }, consumption_total: @averagestariff.select{ |k,v| k[:service] == service }.collect { |e| e[:average]  }.map {|x| x *100/@tariffdivisor } }
      
      end

      @charttariff = LazyHighCharts::HighChart.new('pie') do |f|
            f.chart({:defaultSeriesType=>"pie"})
            if @current_user.admin == 1
              series = {:type=> 'pie',:name=> 'Classification chart',:data=> [@bills_pie_total.select{ |k,v| k[:service] == 1 }.collect { |e| e[:tariff]  }[0], @bills_pie_total.select{ |k,v| k[:service] == 1 }.collect { |e| e[:consumption_total]  }[0]]}
            elsif @current_user.admin == 2
              series = {:type=> 'pie',:name=> 'Classification chart',:data=> [@bills_pie_total.select{ |k,v| k[:service] == 2 }.collect { |e| e[:tariff]  }[0], @bills_pie_total.select{ |k,v| k[:service] == 2 }.collect { |e| e[:consumption_total]  }[0]]}
            elsif @current_user.admin == 3
              series = {:type=> 'pie',:name=> 'Classification chart',:data=> [@bills_pie_total.select{ |k,v| k[:service] == 3 }.collect { |e| e[:tariff]  }[0], @bills_pie_total.select{ |k,v| k[:service] == 3 }.collect { |e| e[:consumption_total]  }[0]]}
            else
              series = {:type=> 'pie',:name=> 'Classification chart',:data=> [['Estrato1', 30.0],['Estrato 4', 22.4],['Estrato 2', 14.2],['Estrato 3', 10.2],['Estrato 5', 17],['Estrato 6', 6.2]]}
            end
            f.series(series)
            f.options[:title][:text] = "Energy"
            f.legend(:layout=> 'vertical',:style=> {:left=> 'auto', :bottom=> 'auto',:right=> '50px',:top=> '100px'}) 
            f.plot_options(:pie=>{:allowPointSelect=>true, :cursor=>"pointer" , :dataLabels=>{:enabled=>true,:color=>"black",:style=>{:font=>"13px Trebuchet MS, Verdana, sans-serif"}}})
      end

      services.each do |service|
        @billsservice << { service: service, value: @bills.select{ |k,v| k[:service] == service}.size }
      end   

    end

  end

  def profile
    @is_current_user = current_user == @user

    @ebills_grid = initialize_grid(
      Bill.unscoped.select('bills.id, bills.consumption, bills.value, bills.date, bills.service').joins("INNER JOIN userbills ON userbills.bill_id = bills.id INNER JOIN users ON userbills.user_id = users.id").where("users.id = ? AND bills.service = 1", @user.id),
      order:           'bills.date',
      order_direction: 'desc',
      per_page: 5
    )
    @wbills_grid = initialize_grid(
      Bill.unscoped.select('bills.id, bills.consumption, bills.value, bills.date, bills.service').joins("INNER JOIN userbills ON userbills.bill_id = bills.id INNER JOIN users ON userbills.user_id = users.id").where("users.id = ? AND bills.service = 2", @user.id),
      order:           'bills.date',
      order_direction: 'desc',
      per_page: 5
    )
    @gbills_grid = initialize_grid(
      Bill.unscoped.select('bills.id, bills.consumption, bills.value, bills.date, bills.service').joins("INNER JOIN userbills ON userbills.bill_id = bills.id INNER JOIN users ON userbills.user_id = users.id").where("users.id = ? AND bills.service = 3", @user.id),
      order:           'bills.date',
      order_direction: 'desc',
      per_page: 5
    )

    @ebills, @wbills, @gbills = [], [], []
    @evbills, @wvbills, @gvbills = [], [], []
    bills = @user.bills.sort_by(&:date)
    bills.each do |b|
      case b.service
      when 1
        @ebills << [b.date.strftime("%s%L").to_i,b.consumption]
        @evbills << [b.date.strftime("%s%L").to_i,b.value / 1000]
      when 2
        @wbills << [b.date.strftime("%s%L").to_i,b.consumption]
        @wvbills << [b.date.strftime("%s%L").to_i,b.value / 1000]
      when 3
        @gbills << [b.date.strftime("%s%L").to_i,b.consumption]
        @gvbills << [b.date.strftime("%s%L").to_i,b.value / 1000]
      end
    end

    if !@is_current_user then
      cu_ebills, cu_wbills, cu_gbills = [], [], []
      cu_evbills, cu_wvbills, cu_gvbills = [], [], []
      cu_bills = current_user.bills.sort_by(&:date)
      cu_bills.each do |b|
        case b.service
        when 1
          cu_ebills << [b.date.strftime("%s%L").to_i,b.consumption]
          cu_evbills << [b.date.strftime("%s%L").to_i,b.value / 1000]
        when 2
          cu_wbills << [b.date.strftime("%s%L").to_i,b.consumption]
          cu_wvbills << [b.date.strftime("%s%L").to_i,b.value / 1000]
        when 3
          cu_gbills << [b.date.strftime("%s%L").to_i,b.consumption]
          cu_gvbills << [b.date.strftime("%s%L").to_i,b.value / 1000]
        end
      end   
    end

    @evchart = LazyHighCharts::HighChart.new('graph') do |f|
      f.chart(height: 280, marginTop: 2, style: {width: 'inherit'})
      f.series(name: [@user.familyname,"'s payment"].join, :yAxis => 0, :data => @evbills, tooltip: {valuePrefix: ' $', valueSuffix: ',000'})
      f.series(name: 'Your payment', :yAxis => 0, :data => cu_evbills, tooltip: {valuePrefix: ' $', valueSuffix: ',000'}) if !@is_current_user
      
      f.rangeSelector(enabled: false)
      f.scrollbar(enabled: false)
    end
    @wvchart = LazyHighCharts::HighChart.new('graph') do |f|
      f.chart(height: 280, marginTop: 2, style: {width: 'inherit'})
      f.series(name: [@user.familyname,"'s payment"].join, :yAxis => 0, :data => @wvbills, tooltip: {valuePrefix: ' $', valueSuffix: ',000'})
      f.series(name: 'Your payment', :yAxis => 0, :data => cu_wvbills, tooltip: {valuePrefix: ' $', valueSuffix: ',000'}) if !@is_current_user
      
      f.rangeSelector(enabled: false)
    end
    @gvchart = LazyHighCharts::HighChart.new('graph') do |f|
      f.chart(height: 280, marginTop: 2, style: {width: 'inherit'})
      f.series(name: [@user.familyname,"'s payment"].join, :yAxis => 0, :data => @gvbills, tooltip: {valuePrefix: ' $', valueSuffix: ',000'})
      f.series(name: 'Your payment', :yAxis => 0, :data => cu_gvbills, tooltip: {valuePrefix: ' $'}) if !@is_current_user
      
      f.rangeSelector(enabled: false)
      f.scrollbar(enabled: false)
    end

    @echart = LazyHighCharts::HighChart.new('graph') do |f|
      f.chart(height: 280, marginTop: 2, style: {width: 'inherit'})
      f.series(name: [@user.familyname,"'s consumption"].join, :yAxis => 0, :data => @ebills, tooltip: {valueSuffix: ' kWh'})
      f.series(name: 'Your consumption', :yAxis => 0, :data => cu_ebills, tooltip: {valueSuffix: ' kWh'}) if !@is_current_user
      
      f.rangeSelector(enabled: false)
      f.scrollbar(enabled: false)
    end
    @wchart = LazyHighCharts::HighChart.new('graph') do |f|
      f.chart(height: 280, marginTop: 2, style: {width: 'inherit'})
      f.series(name: [@user.familyname,"'s consumption"].join, :yAxis => 0, :data => @wbills, tooltip: {valueSuffix: ' kWh'})
      f.series(name: 'Your consumption', :yAxis => 0, :data => cu_wbills, tooltip: {valueSuffix: ' m3'}) if !@is_current_user
      
      f.rangeSelector(enabled: false)
      f.scrollbar(enabled: false)
    end
    @gchart = LazyHighCharts::HighChart.new('graph') do |f|
      f.chart(height: 280, marginTop: 2, style: {width: 'inherit'})
      f.series(name: [@user.familyname,"'s consumption"].join, :yAxis => 0, :data => @gbills, tooltip: {valueSuffix: ' m3'})
      f.series(name: 'Your consumption', :yAxis => 0, :data => cu_gbills, tooltip: {valueSuffix: ' m3'}) if !@is_current_user
      
      f.rangeSelector(enabled: false)
      f.scrollbar(enabled: false)
    end

  end

  def map
    if current_user.has_address?
      users_nearby = current_user.friends

      if current_user.has_address? and current_user.admin?
        users_nearby = current_user.nearbys(10)
      end

      users = [current_user]
      users += users_nearby unless users_nearby.blank?

      @markers = Gmaps4rails.build_markers(users) do |user, marker|
        if user.has_address?
          marker.infowindow render_to_string(:partial => "/layouts/partials/infowindow", :locals => { :user => user} )
          marker.title user.familyname
          marker.json({ :id => user.id})

          marker.lat user.latitude
          marker.lng user.longitude
          marker.picture url: user.consumption_picture, width: 32, height: 37          
        end
      end
    else
      @markers = [ { lat: 10.96421, lng: -74.797043 } ]
    end

    if params[:user_map_id].nil? then
      @user_map = current_user
    else
      @user_map = User.find(params[:user_map_id])
    end  

    @ebills_grid = initialize_grid(
      Bill.unscoped.select('bills.id, bills.consumption, bills.value, bills.date, bills.service').joins("INNER JOIN userbills ON userbills.bill_id = bills.id INNER JOIN users ON userbills.user_id = users.id").where("users.id = ? AND bills.service = 1", @user_map.id),
      order:           'bills.date',
      order_direction: 'desc',
      per_page: 5
    )
    @wbills_grid = initialize_grid(
      Bill.unscoped.select('bills.id, bills.consumption, bills.value, bills.date, bills.service').joins("INNER JOIN userbills ON userbills.bill_id = bills.id INNER JOIN users ON userbills.user_id = users.id").where("users.id = ? AND bills.service = 2", @user_map.id),
      order:           'bills.date',
      order_direction: 'desc',
      per_page: 5
    )
    @gbills_grid = initialize_grid(
      Bill.unscoped.select('bills.id, bills.consumption, bills.value, bills.date, bills.service').joins("INNER JOIN userbills ON userbills.bill_id = bills.id INNER JOIN users ON userbills.user_id = users.id").where("users.id = ? AND bills.service = 3", @user_map.id),
      order:           'bills.date',
      order_direction: 'desc',
      per_page: 5
    )

    @ebills, @wbills, @gbills = [], [], []
    @evbills, @wvbills, @gvbills = [], [], []
    bills = @user_map.bills.sort_by(&:date)
    bills.each do |b|
      case b.service
      when 1
        @ebills << [b.date.strftime("%s%L").to_i,b.consumption]
        @evbills << [b.date.strftime("%s%L").to_i,b.value / 1000]
      when 2
        @wbills << [b.date.strftime("%s%L").to_i,b.consumption]
        @wvbills << [b.date.strftime("%s%L").to_i,b.value / 1000]
      when 3
        @gbills << [b.date.strftime("%s%L").to_i,b.consumption]
        @gvbills << [b.date.strftime("%s%L").to_i,b.value / 1000]
      end
    end

    if !@is_current_user then
      cu_ebills, cu_wbills, cu_gbills = [], [], []
      cu_evbills, cu_wvbills, cu_gvbills = [], [], []
      cu_bills = current_user.bills.sort_by(&:date)
      cu_bills.each do |b|
        case b.service
        when 1
          cu_ebills << [b.date.strftime("%s%L").to_i,b.consumption]
          cu_evbills << [b.date.strftime("%s%L").to_i,b.value / 1000]
        when 2
          cu_wbills << [b.date.strftime("%s%L").to_i,b.consumption]
          cu_wvbills << [b.date.strftime("%s%L").to_i,b.value / 1000]
        when 3
          cu_gbills << [b.date.strftime("%s%L").to_i,b.consumption]
          cu_gvbills << [b.date.strftime("%s%L").to_i,b.value / 1000]
        end
      end   
    end

    @evchart = LazyHighCharts::HighChart.new('graph') do |f|
      f.chart(height: 280, marginTop: 2, style: {width: 'inherit'})

      f.series(name: [@user_map.familyname,"'s payment"].join, :yAxis => 0, :data => @evbills, tooltip: {valuePrefix: ' $', valueSuffix: ',000'})
      f.series(name: 'Your payment', :yAxis => 0, :data => cu_evbills, tooltip: {valuePrefix: ' $', valueSuffix: ',000'}) if !@is_current_user
      
      f.rangeSelector(enabled: false)
      f.scrollbar(enabled: false)
    end
    @wvchart = LazyHighCharts::HighChart.new('graph') do |f|
      f.chart(height: 280, marginTop: 2, style: {width: 'inherit'})

      f.series(name: [@user_map.familyname,"'s payment"].join, :yAxis => 0, :data => @wvbills, tooltip: {valuePrefix: ' $', valueSuffix: ',000'})
      f.series(name: 'Your payment', :yAxis => 0, :data => cu_wvbills, tooltip: {valuePrefix: ' $', valueSuffix: ',000'}) if !@is_current_user
      
      f.rangeSelector(enabled: false)
      f.scrollbar(enabled: false)
    end
    @gvchart = LazyHighCharts::HighChart.new('graph') do |f|
      f.chart(height: 280, marginTop: 2, style: {width: 'inherit'})

      f.series(name: [@user_map.familyname,"'s payment"].join, :yAxis => 0, :data => @gvbills, tooltip: {valuePrefix: ' $', valueSuffix: ',000'})
      f.series(name: 'Your payment', :yAxis => 0, :data => cu_gvbills, tooltip: {valuePrefix: ' $', valueSuffix: ',000'}) if !@is_current_user
      
      f.rangeSelector(enabled: false)
      f.scrollbar(enabled: false)
    end

    @echart = LazyHighCharts::HighChart.new('graph') do |f|
      f.chart(height: 280, marginTop: 2, style: {width: 'inherit'})

      f.series(name: [@user_map.familyname,"'s consumption"].join, :yAxis => 0, :data => @ebills, tooltip: {valueSuffix: ' kWh'})
      f.series(name: 'Your consumption', :yAxis => 0, :data => cu_ebills, tooltip: {valueSuffix: ' kWh'}) if !@is_current_user
      
      f.rangeSelector(enabled: false)
      f.scrollbar(enabled: false)
    end
    @wchart = LazyHighCharts::HighChart.new('graph') do |f|
      f.chart(height: 280, marginTop: 2, style: {width: 'inherit'})

      f.series(name: [@user_map.familyname,"'s consumption"].join, :yAxis => 0, :data => @wbills, tooltip: {valueSuffix: ' m3'})
      f.series(name: 'Your consumption', :yAxis => 0, :data => cu_wbills, tooltip: {valueSuffix: ' m3'}) if !@is_current_user
            
      f.rangeSelector(enabled: false)
      f.scrollbar(enabled: false)
    end
    @gchart = LazyHighCharts::HighChart.new('graph') do |f|
      f.chart(height: 280, marginTop: 2, style: {width: 'inherit'})

      f.series(name: [@user_map.familyname,"'s consumption"].join, :yAxis => 0, :data => @gbills, tooltip: {valueSuffix: ' m3'})
      f.series(name: 'Your consumption', :yAxis => 0, :data => cu_gbills, tooltip: {valueSuffix: ' m3'}) if !@is_current_user
            
      f.rangeSelector(enabled: false)
      f.scrollbar(enabled: false)
    end

  end

end
