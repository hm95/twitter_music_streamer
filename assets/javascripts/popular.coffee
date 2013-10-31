$ ->

  # Grab feed and populate index
  $.get "/popularfeed.json",((data) ->

    feed  = JSON.parse(data[0]["result"])
    i     = 0

    while i < 101
      if i >= feed.length
        break

      rank      = i+1
      #titleArr  = feed[i]["title"].split(" - ")
      #title     = if (titleArr[1] == undefined) then titleArr[0] else titleArr[1]
      #artist    = if (titleArr[1] == undefined) then '' else titleArr[0]

      title  = feed[i]["title"]
      title = (title.substring(0,40) + "...")  if title.length > 40

      vidTemplate = '<div class="vid"><div class="vidDetails"><div class="rank">' + rank + '</div><div class="vidTitle">' + title + '</div><div class="vidArtist">' + '</div></div><img src="http://img.youtube.com/vi/' + feed[i]["id"] + '/0.jpg" id="' + feed[i]["id"] + '"></div>'
      $('.container').append(vidTemplate)
      i++

    # Populate geo locations array
    geoSongArray = []
    gObj =
      count: 0
      name: ""
    for o of feed
      geoSong = feed[o]["geo"]
      gObjArray = []

      for g of geoSong
        # console.log(g)
        # console.log(geoSong[g])
        gObj.name = g
        gObj.count = geoSong[g]
        gObjArray.push(gObj)
      # console.log(gObj)

      geoSongArray.push(gObjArray)
      # console.log(geoSongArray[0])

    # Adding analytics charts
    # Basic template of charts we should use (spline/column)
    labelColor  = "#2c2c2c"
    axisColor   = "#2c2c2c"

    chart1 = new Highcharts.Chart(
      chart:
        renderTo: "tweetTrend"

      title:
        text: "Hourly Tweet Trend1"

      legend:
        enable: false

      xAxis: [categories: [geoSongArray[0].name, "Afternoon", "Night"]]
      yAxis: [
        labels:
          style:
            color: axisColor

          align: "left"
          x: 0
          y: -2

        showFirstLabel: false
        title:
          text: "Number of Tweets"
          style:
            color: labelColor
      ]
      series: [
        name: "Number of Tweets"
        color: "#FF6868"
        type: "spline"
        data: [1, 3]
      ]
    )

    chart2 = new Highcharts.Chart(
      chart:
        renderTo: "language"

      title:
        text: "Hourly Tweet Trend2"

      legend:
        enable: false

      xAxis: [categories: ["1pm", "2pm"]]
      yAxis: [
        labels:
          style:
            color: axisColor

          align: "left"
          x: 0
          y: -2

        showFirstLabel: false
        title:
          text: "Number of Tweets"
          style:
            color: labelColor
      ]
      series: [
        name: "Number of Tweets"
        color: "#AAFFD3"
        type: "column"
        data: [1, 3]
      ]
    )

    chart3 = new Highcharts.Chart(
      chart:
        renderTo: "geo"

      title:
        text: "Geographic Trend"

      legend:
        enable: false

      xAxis: [categories: ["1pm", "2pm"]]
      yAxis: [
        labels:
          style:
            color: axisColor

          align: "left"
          x: 0
          y: -2

        showFirstLabel: false
        title:
          text: "Number of Tweets"
          style:
            color: labelColor
      ]
      series: [
        name: "Number of Tweets"
        color: "#ACD6FF"
        type: "column"
        data: [1, 3]
      ]
    )

    # console.log(geoSongArray[0])


    console.log(feed)
    songArrayCountries = []
    songArrayCounts = []

    songArrayLanguages = []
    songArrayLanguageCounts = []

    songArrayTimes = []
    songArrayTimeCounts = []

    for o of feed
      eachSongGeo = feed[o].geo
      eachSongLang = feed[o].language
      eachSongTime = feed[o].popular_time
      countries = []
      counts = []
      languages = []
      langCounts = []
      times = []
      timeCounts = []
      for i of eachSongGeo
        countries.push(i);
        counts.push(eachSongGeo[i]);
      songArrayCountries.push(countries)
      songArrayCounts.push(counts)
      for j of eachSongLang
        languages.push(j)
        langCounts.push(eachSongLang[j])
      songArrayLanguages.push(languages)
      songArrayLanguageCounts.push(langCounts)
      for k of eachSongTime
        times.push(k)
        timeCounts.push(eachSongTime[k])
      songArrayTimes.push(times)
      songArrayTimeCounts.push(timeCounts)

    # Display and hide overlay
    $('.vidDetails').on('click',
      ->
        videoID   = $(this).siblings('img').attr('id')
        url       = "http://www.youtube.com/embed/" + videoID
        $('#overlay').addClass('show')
        $('#overlay iframe').attr('src', url)
        r = $(this).children('.rank').text()

        fiveCountryCounts = []
        fiveCountries = []
        fiveLanguageCounts = []
        fiveLanguages = []
        fiveTimeCounts= []
        fiveTimes = []
        i = 0
        while i < 5
          if songArrayCounts[r-1][i]
            fiveCountryCounts.push(songArrayCounts[r-1][i])
          if songArrayCountries[r-1][i]
            fiveCountries.push(songArrayCountries[r-1][i])
          if songArrayLanguageCounts[r-1][i]
            fiveLanguageCounts.push(songArrayLanguageCounts[r-1][i])
          if songArrayLanguages[r-1][i]
            fiveLanguages.push(songArrayLanguages[r-1][i])
          if songArrayTimeCounts[r-1][i]
            fiveTimeCounts.push(songArrayTimeCounts[r-1][i])
          if songArrayTimes[r-1][i]
            fiveTimes.push(songArrayTimes[r-1][i])
          i++
        console.log(fiveTimes)
        console.log(fiveCountries)

        # Adding analytics charts
        # Basic template of charts we should use (spline/column)
        labelColor  = "#2c2c2c"
        axisColor   = "#2c2c2c"

        chart1 = new Highcharts.Chart(
          chart:
            renderTo: "tweetTrend"

          title:
            text: "Tweets by Geography"

          legend:
            enable: false

          xAxis: [categories: fiveCountries]
          yAxis: [
            labels:
              style:
                color: axisColor

              align: "left"
              x: 0
              y: -2

            showFirstLabel: false
            title:
              text: "Number of Tweets"
              style:
                color: labelColor
          ]
          series: [
            name: "Number of Tweets"
            color: "#FF6868"
            type: "spline"
            data: fiveCountryCounts
          ]
        )

        chart2 = new Highcharts.Chart(
          chart:
            renderTo: "language"

          title:
            text: "Tweets by Language"

          legend:
            enable: false

          xAxis: [categories: fiveLanguages]
          yAxis: [
            labels:
              style:
                color: axisColor

              align: "left"
              x: 0
              y: -2

            showFirstLabel: false
            title:
              text: "Number of Tweets"
              style:
                color: labelColor
          ]
          series: [
            name: "Number of Tweets"
            color: "#AAFFD3"
            type: "column"
            data: fiveLanguageCounts
          ]
        )

        chart3 = new Highcharts.Chart(
          chart:
            renderTo: "geo"

          title:
            text: "Time of the Day"

          legend:
            enable: false

          xAxis: [categories: fiveTimes]
          yAxis: [
            labels:
              style:
                color: axisColor

              align: "left"
              x: 0
              y: -2

            showFirstLabel: false
            title:
              text: "Number of Tweets"
              style:
                color: labelColor
          ]
          series: [
            name: "Number of Tweets"
            color: "#ACD6FF"
            type: "column"
            data: fiveTimeCounts
          ]
        )
    )
    $('#overlay').on('click',
      ->
        $(this).removeClass('show')
        $('#overlay iframe').attr('src', '')
    )
  ), "json" # End of .get() call, fix this.
