###*
 * @module       RD Navbar
 * @author       Evgeniy Gusarov
 * @see          https://ua.linkedin.com/pub/evgeniy-gusarov/8a/a40/54a
 * @version      2.1.0
###

# Global flags
isTouch = "ontouchstart" of window

(($, document, window) ->
  ###*
   * Creates a RDNavbar.
   * @class RDNavbar.
   * @public
   * @param {HTMLElement} element - The element to create the RDNavbar for.
   * @param {Object} [options] - The options
  ###
  class RDNavbar
    ###*
     * Default options for RDNavbar.
     * @protected
    ###
    Defaults:
      layout: 'rd-navbar-static'
      deviceLayout: 'rd-navbar-fixed'
      focusOnHover: true
      focusOnHoverTimeout: 800
      linkedElements: ["html"]
      domAppend: true
      stickUp: true
      stickUpClone: true
      stickUpOffset: '100%'
      anchorNavSpeed: 400
      anchorNavOffset: 0
      anchorNavEasing: 'swing'
      responsive:
        0:
          layout: "rd-navbar-fixed"
          focusOnHover: false
          stickUp: false
        992:
          layout: "rd-navbar-static"
          focusOnHover: true
          stickUp: true
      callbacks:
        onToggleSwitch: false
        onToggleClose: false
        onDomAppend: false
        onDropdownOver: false
        onDropdownOut: false
        onDropdownToggle: false
        onDropdownClose: false
        onStuck: false
        onUnstuck: false
        onAnchorChange: false

    constructor: (element, options) ->
      ###*
       * Current options set
       * @public
      ###
      @.options = $.extend(false, {}, @Defaults, options)

      ###*
       * Plugin element
       * @public
      ###
      @.$element = $(element)

      ###*
       * Plugin element clone
       * @public
      ###
      @.$clone = null;

      ###*
       * Additional references
       * @public
      ###
      @.$win = $(window)
      @.$doc = $(document)
      @.currentLayout = @.options.layout
      @.loaded = false
      @.focusOnHover = @.options.focusOnHover
      @.focusTimer = false
      @.cloneTimer = false
      @.isStuck = false

      @initialize()

    ###*
     * Initializes the RDNavbar.
     * @protected
    ###
    initialize: () ->
      ctx = @
      ctx.$element.addClass("rd-navbar").addClass(ctx.options.layout)
      ctx.$element.addClass("rd-navbar--is-touch") if isTouch

      @.createNav(ctx) if ctx.options.domAppend
      @.createClone(ctx) if ctx.options.stickUpClone
      @.applyHandlers(ctx)
      @.offset = ctx.$element.offset().top
      @.height = ctx.$element.outerHeight()
      @.loaded = true

      return ctx

    ###*
    * Changes {ctx.$element} layout basing on screen resolution
    * @protected
    ###
    resize: (ctx, e) ->
      targetLayout = if isTouch then ctx.getOption('deviceLayout') else ctx.getOption('layout')
      targetElement = ctx.$element.add(ctx.$clone)

      if targetLayout isnt ctx.currentLayout or !ctx.loaded

        ctx.switchClass(targetElement, ctx.currentLayout, targetLayout)

        #Change layout of linked elements
        $.grep(ctx.options.linkedElements, (link, index) ->
          ctx.switchClass(link, ctx.currentLayout + '-linked', targetLayout + '-linked')
        ) if ctx.options.linkedElements?

        ctx.currentLayout = targetLayout

      ctx.focusOnHover = ctx.getOption('focusOnHover')

      return ctx

    ###*
    * Toggles bar stickup on scroll
    * @protected
    ###
    stickUp: (ctx, e) ->
      stickUp = ctx.getOption("stickUp")
      scrollTop = ctx.$doc.scrollTop()
      targetElement = if ctx.$clone? then ctx.$clone else ctx.$element
      stickUpOffset = ctx.getOption('stickUpOffset')
      threshold = (if typeof stickUpOffset is 'string' then (if stickUpOffset.indexOf('%') > 0 then parseFloat(stickUpOffset) * ctx.height / 100 else parseFloat(stickUpOffset)) else stickUpOffset)

      if stickUp
        if (scrollTop >= threshold and !ctx.isStuck) || (scrollTop < threshold and ctx.isStuck)
          ctx.$element
            .add(ctx.$clone)
            .find('[data-rd-navbar-toggle]')
            .each(()->
              $.proxy(ctx.closeToggle, @)(ctx, false)
              return
            )
            .end()
            .find('.rd-navbar-submenu').removeClass('opened').removeClass('focus')

          if scrollTop >= threshold and !ctx.isStuck
            if e.type is 'resize'
              ctx.switchClass(targetElement, '', 'rd-navbar--is-stuck')
            else
              targetElement.addClass('rd-navbar--is-stuck')
            ctx.isStuck = true
            ctx.options.callbacks.onStuck.call(ctx) if ctx.options.callbacks.onStuck
          else
            if e.type is 'resize'
              ctx.switchClass(targetElement, 'rd-navbar--is-stuck', '')
            else
              targetElement
                .removeClass('rd-navbar--is-stuck')
                .one(
                  'transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd',
                  $.proxy(ctx.resizeWrap, ctx, e))
            ctx.isStuck = false
            ctx.options.callbacks.onUnstuck.call(ctx) if ctx.options.callbacks.onUnstuck
      else
        if ctx.isStuck
          ctx.switchClass(targetElement, 'rd-navbar--is-stuck', '')
          ctx.isStuck = false
          ctx.resizeWrap(e)

      return ctx

    ###*
    * Resizes an external wrap of navbar
    * @protected
    ###
    resizeWrap: (e)->
      ctx = @
      if !ctx.$clone? and !ctx.isStuck
        $wrap = ctx.$element.parent()
        ctx.height = ctx.$element.outerHeight()

        if e.type is 'resize'
          $wrap
            .addClass('rd-navbar--no-transition')
            .css('height', ctx.height)

          #Trigger a reflow, flushing the CSS changes
          $wrap[0].offsetHeight

          $wrap.removeClass('rd-navbar--no-transition')
        else
          $wrap.css('height', ctx.height)

    ###*
    * Creates additional DOM for navigation functionality
    * @protected
    ###
    createNav: (ctx) ->
      ctx.$element
        .find('.rd-navbar-dropdown, .rd-navbar-megamenu')
        .each(() ->
          $this = $(@)
          if $this.hasClass('rd-navbar-megamenu') then $this.parent().addClass('rd-navbar--has-megamenu') else $this.parent().addClass('rd-navbar--has-dropdown'))
        .parents("li")
        .addClass("rd-navbar-submenu")
        .append($('<span/>', {'class' : 'rd-navbar-submenu-toggle'}))

      ctx.options.callbacks.onDomAppend.call(@) if ctx.options.callbacks.onDomAppend

      return ctx

    ###*
    * Creates navbar clone to stick up
    * @protected
    ###
    createClone: (ctx) ->
      ctx.$clone = ctx.$element.clone().insertAfter(ctx.$element).addClass('rd-navbar--is-clone')
      return ctx

    ###*
    * Closes all toggles on outside click of each item
    * @protected
    ###
    closeToggle: (ctx, e) ->
      $target = $(e.target)
      collapse = false

      if e.target isnt @ and !$target.parents('[data-rd-navbar-toggle]').length and linkedElements = @.getAttribute('data-rd-navbar-toggle')
        $items = $(@).parents('.rd-navbar').find(linkedElements).add($(@).parents('.rd-navbar')[0])
        $items.each(()->
          if !collapse
            collapse = (e.target is @ or $.contains(@, e.target)) is true
        );
        if !collapse
          $items.add(@).removeClass('active')
          ctx.options.callbacks.onToggleClose.call(@, ctx) if ctx.options.callbacks.onToggleClose
      return @

    ###*
    * Switches toggle
    * @protected
    ###
    switchToggle: (ctx, e) ->
      e.preventDefault()
      if linkedElements = @.getAttribute('data-rd-navbar-toggle')
        $('[data-rd-navbar-toggle]').not(@).each(()->
          if deactivateElements = @.getAttribute('data-rd-navbar-toggle')
            $(@).parents('.rd-navbar')
              .find(deactivateElements)
              .add(@)
              .add(if $.inArray('.rd-navbar', deactivateElements.split(/\s*,\s*/i)) > -1 then $(@).parents('.rd-navbar')[0] else false)
              .removeClass('active')
        )
        $(@).parents('.rd-navbar')
          .find(linkedElements)
          .add(@)
          .add(if $.inArray('.rd-navbar', linkedElements.split(/\s*,\s*/i)) > -1 then $(@).parents('.rd-navbar')[0] else false)
          .toggleClass('active')
        ctx.options.callbacks.onToggleSwitch.call(@, ctx) if ctx.options.callbacks.onToggleSwitch
      return @

    ###*
    * Triggers submenu popup to be shown on mouseover
    * @protected
    ###
    dropdownOver: (ctx, timer) ->
      if ctx.focusOnHover and !isTouch
        $this = $(@)
        clearTimeout(timer)
        $this.addClass('focus').siblings().removeClass('opened').each(ctx.dropdownUnfocus)
        ctx.options.callbacks.onDropdownOver.call(@, ctx) if ctx.options.callbacks.onDropdownOver

      return @

    ###*
    * Triggers submenu popop to be hidden on mouseout
    * @protected
    ###
    dropdownOut: (ctx, timer) ->
      if ctx.focusOnHover and !isTouch
        $this = $(@);

        $this.one('mouseenter.navbar', () ->
          clearTimeout(timer)
        )

        clearTimeout(timer)
        timer = setTimeout($.proxy(ctx.dropdownUnfocus, @, ctx), ctx.options.focusOnHoverTimeout)

        ctx.options.callbacks.onDropdownOut.call(@, ctx) if ctx.options.callbacks.onDropdownOut
      return @

    ###*
    * Removes a focus from submenu
    * @protected
    ###
    dropdownUnfocus: (ctx) ->
      $this = $(@)
      $this.find('li.focus').add(@).removeClass('focus')
      return @

    ###*
    * Closes submenu
    * @protected
    ###
    dropdownClose: (ctx, e) ->
      if e.target isnt @ and !$(e.target).parents('.rd-navbar-submenu').length
        $this = $(@)
        $this.find('li.focus').add(@).removeClass('focus').removeClass('opened')
        ctx.options.callbacks.onDropdownClose.call(@, ctx) if ctx.options.callbacks.onDropdownClose
      return @

    ###*
    * Toggles submenu popup to be shown on trigger click
    * @protected
    ###
    dropdownToggle: (ctx) ->
      $(this).toggleClass('opened').siblings().removeClass('opened')
      ctx.options.callbacks.onDropdownToggle.call(@, ctx) if ctx.options.callbacks.onDropdownToggle
      return @

    ###*
    * Scrolls the page to triggered anchor
    * @protected
    ###
    goToAnchor: (ctx, e)->
      hash = @.hash
      $anchor = $(hash)

      if $anchor.length
        e.preventDefault()
        $('html, body').stop().animate(
          'scrollTop': $anchor.offset().top + ctx.getOption('anchorNavOffset') + 1
          ctx.getOption('anchorNavSpeed')
          ctx.getOption('anchorNavEasing')
          ()->
            ctx.changeAnchor(hash)
        )
      return @

    ###*
    * Highlight an active anchor
    * @protected
    ###
    activateAnchor: (e)->
      ctx = @
      scrollTop = ctx.$doc.scrollTop()
      winHeight = ctx.$win.height()
      docHeight = ctx.$doc.height()
      navOffset = ctx.getOption('anchorNavOffset')

      if scrollTop + winHeight > docHeight - 50
        $anchor = $('[data-type="anchor"]').last()

        if $anchor.length
          if $anchor.offset().top >= scrollTop
            hash = '#' + $anchor.attr("id")
            $item = $('.rd-navbar-nav a[href^="' + hash + '"]').parent()
            if !$item.hasClass('active')
              $item
                .addClass('active')
                .siblings()
                .removeClass('active')
              ctx.options.callbacks.onAnchorChange.call($anchor[0], ctx) if ctx.options.callbacks.onAnchorChange
        return $anchor
      else
        links = $('.rd-navbar-nav a[href^="#"]').get()
        for i, link of links
          $link = $(link)
          hash = $link.attr('href')
          $anchor = $(hash)

          if $anchor.length
            if $anchor.offset().top + navOffset <= scrollTop and
               $anchor.offset().top + $anchor.outerHeight() > scrollTop
              $link.parent().addClass('active').siblings().removeClass('active')
              ctx.options.callbacks.onAnchorChange.call($anchor[0], ctx) if ctx.options.callbacks.onAnchorChange

      return null

    ###*
    * Returns current anchor
    * @protected
    ###
    getAnchor: () ->
      if history
        if history.state
          return history.state.id
      return null

    ###*
    * Changes current page anchor
    * @protected
    ###
    changeAnchor: (hash)->
      if history
        if history.state
          if history.state.id isnt hash
            history.replaceState({'anchorId': hash}, null, hash)
          else
            history.pushState({'anchorId': hash}, null, hash)
        else
          history.pushState({'anchorId': hash}, null, hash)

      return @

    ###*
    * Applies all JS event handlers
    * @protected
    ###
    applyHandlers: (ctx) ->
      # Enables dynamic options changes if responsive
      if ctx.options.responsive?
        ctx.$win
        .on('resize.navbar', $.proxy(ctx.resize, ctx.$win[0], ctx))
        .on('resize.navbar', $.proxy(ctx.resizeWrap, ctx))
        .on('resize.navbar', $.proxy(ctx.stickUp, (if ctx.$clone? then ctx.$clone else ctx.$element), ctx))
        .on('orientationchange.navbar', $.proxy(ctx.resize, ctx.$win[0], ctx))
        .trigger('resize.navbar')

      # Enables Stick up event
      ctx.$doc
        .on('scroll.navbar', $.proxy(ctx.stickUp, (if ctx.$clone? then ctx.$clone else ctx.$element), ctx))
        .on('scroll.navbar', $.proxy(ctx.activateAnchor, ctx))

      # Enables Navbar toggles
      ctx.$element.add(ctx.$clone)
        .find('[data-rd-navbar-toggle]')
        .each(()->
          $this = $(@)
          $this.on((if isTouch then 'touchstart' else 'click'), $.proxy(ctx.switchToggle, @, ctx))
          $this.parents('body')
            .on((if isTouch then 'touchstart' else 'click'), $.proxy(ctx.closeToggle, @, ctx))
        )

      # Enables Submenu events
      ctx.$element.add(ctx.$clone)
        .find('.rd-navbar-submenu')
        .each(()->
          $this = $(@)
          timer = if $this.parents(".rd-navbar--is-clone").length then ctx.cloneTimer else ctx.focusTimer

          $this.on('mouseleave.navbar', $.proxy(ctx.dropdownOut, @, ctx, timer))
          $this.find('> a').on('mouseenter.navbar', $.proxy(ctx.dropdownOver, @, ctx, timer))
          $this.find('> .rd-navbar-submenu-toggle')
            .on((if isTouch then 'touchstart' else 'click'), $.proxy(ctx.dropdownToggle, @, ctx))
          $this.parents('body')
            .on((if isTouch then 'touchstart' else 'click'), $.proxy(ctx.dropdownClose, @, ctx))
        )

      # Enables OnePage Nav
      ctx.$element.add(ctx.$clone)
        .find('.rd-navbar-nav a[href^="#"]')
        .each(()->
          $(@).on((if isTouch then 'touchstart' else 'click'), $.proxy(ctx.goToAnchor, @, ctx))
        )

      return ctx

    ###*
    * Switches classes of elements without transition
    * @protected
    ###
    switchClass: (element, before, after)->
      obj = if element instanceof jQuery then element else $(element)
      obj
        .addClass('rd-navbar--no-transition')
        .removeClass(before)
        .addClass(after)

      #Trigger a reflow, flushing the CSS changes
      obj[0].offsetHeight

      obj.removeClass('rd-navbar--no-transition')

    ###*
    * Gets specific option of plugin
    * @protected
    ###
    getOption: (key)->
      for point of @.options.responsive
        if point <= @.$win.width() then targetPoint = point
      if @.options.responsive[targetPoint][key]? then @.options.responsive[targetPoint][key] else @.options[key]


  ###*
   * The jQuery Plugin for the RD Navbar
   * @public
  ###
  $.fn.extend RDNavbar: (options) ->
    $this = $(this)
    if !$this.data('RDNavbar')
      $this.data 'RDNavbar', new RDNavbar(this, options)

  ###*
  * RD Navbar window export
  * @public
  ###
  window.RDNavbar = RDNavbar

) window.jQuery, document, window

###*
 * The Plugin AMD export
 * @public
###
if module?
  module.exports = window.RDNavbar
else if typeof define is 'function' && define.amd
  define(["jquery"], () ->
    'use strict'
    return window.RDNavbar
  )