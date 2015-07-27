class Dashing.HaproxyDownHosts extends Dashing.Widget
  width = 5

  ready: ->
    $(@node).find('.gridster ul').gridster({
      max_cols: width,
      min_cols: width
    })

  onData: (data) ->
    grid = $(@node).find('.gridster ul')
    gridster = grid.gridster().data('gridster')

    # Add class expired to every widget
    $(grid.find('li')).each (i,e) ->
      $(e).addClass "expired"

    for k, host of data.hosts
      id = host.label + '-' + host.pxname + '-' + host.svname
      widget = grid.find('li[id="'+id+'"]')

      if !widget.length
        widget = gridster.add_widget('<li id="'+id+'"><div class="widget widget-haproxy-down-host"><h1 id="host"></h1><p id="svname"></p><p><span id="status"></span> <span id="downtime"></span>s</p><p id="sessions">Sessions: <span></span></p></div></li>');
        widget.find('#host').text(host.label)
        widget.find('#svname').text(host.svname)
      else
        $(widget).removeClass "expired"

      widget.find('#status').text(host.status)
      widget.find('#downtime').text(host.downtime)
      widget.find('#sessions span').text(host.sessions)

      if host.status == 'MAINT'
        widget.css( "background-color", "#BC4B8C" );
      else
        widget.css( "background-color", "#C44435" );

    # Remove expired widgets
    $(grid.find('li.expired')).each (i, widget) ->
      gridster.remove_widget( widget, (removedNode) ->
        # Redraw the grid - this isn't automagical
        $(grid.find('li')).each (i, widget) ->
          $(widget).attr 'data-col', i%width+1
          $(widget).attr 'data-row', Math.ceil((i+1)/width)
    )
