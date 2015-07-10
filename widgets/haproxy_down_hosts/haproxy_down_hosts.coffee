class Dashing.HaproxyDownHosts extends Dashing.Widget

  ready: ->
    # This is fired when the widget is done being rendered
    $(@node).find('.gridster ul').gridster({
      max_cols: 4
      min_cols: 4
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
        widget = gridster.add_widget('<li id="'+id+'"><div class="widget widget-haproxy-down-host"><h1 id="host"></h1><p id="svname"></p><p id="status"></p><p id="downtime"><span></span>s</p><p id="sessions">Sessions: <span></span></p></div></li>');
        widget.find('#host').text(host.label)
        widget.find('#svname').text(host.svname)
      else
        $(widget).removeClass "expired"

      widget.find('#status').text(host.status)
      widget.find('#downtime span').text(host.downtime)
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
          $(widget).attr 'data-col', i%4+1
          $(widget).attr 'data-row', Math.ceil((i+1)/4)
    )
