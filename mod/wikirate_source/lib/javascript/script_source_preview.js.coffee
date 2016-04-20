@testSameOrigin = (testUrl, pageN) ->
  $.getJSON 'Source.json?view=check_iframable&url=' + testUrl, (data) ->
    if !data.result
      #remove iframe and show redirection message
      $('#webpage-preview').html ''
      $redirectNotice = $('<div>', 'class': 'redirect-notice')
      if pageN != ''
        #locally
        #Page_000001545?view=content&slot[structure]=source%20item%20preview
        $.ajax('/' + pageN + '?view=content&slot[structure]=source_item_preview').done((noteFormHtml) ->
          $redirectNotice.append noteFormHtml
          $redirectNotice.trigger 'slotReady'
          return
        ).fail (xhr, ajaxOptions, thrownError) ->
          html = $(xhr.responseText)
          html.find('.card-header').remove()
          $redirectNotice.append html
          return
      $('#webpage-preview').append $redirectNotice
      $('#webpage-preview').addClass 'non-previewable'
    return
  return

@resizeIframe = ->
  $('.webpage-preview').height $(window).height() - $('.navbar').height() - 1
  return


wagn.slotReady (slot) ->
  if $('body').attr('id') == 'source-preview-page-layout'
    # closeTabContent()
    $('[data-toggle="source_preview_tab_ajax"]').click (e) ->
      $this = $(this)
      loadurl = $this.attr('href')
      targ = $this.attr('data-target')
      if undefined != loadurl
        $.get loadurl, (data) ->
          $(targ).html data
          return
      $this.tab 'show'
      false
    $('#logo-bar').dblclick ->
      false
    pageName = $('#source-name').html()
    url = $('#source_url').html()
    if url
      testSameOrigin url, pageName
    resizeIframe()
    $('[data-target="#tab_claims"]').trigger 'click'
  return