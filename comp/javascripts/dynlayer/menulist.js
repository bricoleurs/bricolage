// MenuList Object
// a cascading menu widget utilizing the List Object
// 19990326

// Copyright (C) 1999 Dan Steinman
// Distributed under the terms of the GNU Library General Public License
// Available at http://www.dansteinman.com/dynapi/

// Thanks to: Knut Dale <Knut.S.Dale@eto.ericsson.se>

function MenuList() {
	// main-menu constructor (x,y,width,itemH)
	// sub-menu constructor (parentMenu,parentItemIndex)

	this.name = "MenuList"+(MenuList.count++)
	this.obj = this.name + "MenuListObject"
	eval(this.obj + "=this")
	if (arguments.length==4) {
		this.isChild = false
		this.x = arguments[0]
		this.y = arguments[1]
		this.w = arguments[2]
		this.itemH = arguments[3]
		this.subOnSelect = false
		this.offsetX = -1
		this.offsetY = 0
	}
	else {
		this.isChild = true
		this.parent = arguments[0]
		var index = arguments[1]
		this.parent.list.items[index].hasImage = true
		this.parent.list.items[index].hasChild = true
		this.parent.list.items[index].child = this
		this.x = this.parent.w // add pixels here for btwn menu spacing
		this.y = this.parent.list.items[index].y
		this.w = (arguments.length==3)? arguments[2] : this.parent.w
		this.itemH = this.parent.itemH
		this.childShown = null
		this.subOnSelect = this.parent.subOnSelect
		this.offsetX = this.parent.offsetX
		this.offsetY = this.parent.offsetY
	}

//	this.visibility = 'inherit'
	this.visibility = 'hidden'
	this.zIndex = 100
	this.overOpen = false
	
	this.list = new List(1,1,this.w-2,this.itemH)
	this.list.visibility = 'inherit'
	this.list.allowDeselect = true
	this.list.menulist = this
	
	if (this.isChild) {
		this.list.image = this.parent.list.image
		this.list.color = this.parent.list.color
		this.list.itemSpacing = this.parent.list.itemSpacing
		this.list.fontname = this.parent.list.fontname
		this.list.fontsize = this.parent.list.fontsize
	}
	
	this.cssChildren = ''
	this.divChildren = ''

	this.build = MenuListBuild
	this.activate = MenuListActivate
	this.showMenu = MenuListShowMenu
	this.hideMenu = MenuListHideMenu
	this.show = MenuListShow
	this.hide = MenuListHide
	this.toggle = MenuListToggle
	this.select = MenuListSelect
	if (this.isChild) this.onSelect = this.parent.onSelect
	else this.onSelect = new Function()
}
function MenuListBuild(write) {
	for (var i=0;i<this.list.items.length;i++) {
		if (this.list.items[i].hasChild) {
			this.list.items[i].child.overOpen = this.overOpen
			this.list.items[i].child.build()
		}
	}
	this.list.overOpen = this.overOpen
	this.list.build()
	this.css = css(this.name,this.x+this.offsetX,this.y+this.offsetY,null,null,null,(this.isChild)?'hidden':this.visibility,this.zIndex)+
	css(this.name+'ListW',0,0,this.w,this.list.h+2,'black')+
	this.list.css+
	this.cssChildren

	if (this.name == "MenuList0") {
	
		this.div = '<div id="'+this.name+'" onClick="hidemenu()">\n'
	} else {
		this.div = '<div id="'+this.name+'">\n'
	}
	
	this.div += '<div id="'+this.name+'ListW">\n'+
	this.list.div+
	'</div>\n'+
	this.divChildren+
	'</div>\n'

	if (this.isChild) {
		this.parent.cssChildren += this.css
		this.parent.divChildren += this.div
	}
}
function MenuListActivate() {
	this.list.activate()
	this.lyr = new DynLayer(this.name)
	this.h = this.list.h+2
	if (is.ns && !this.isChild) {
		this.lyr.clipInit()
		this.lyr.clipTo(0,this.w,this.h,0)
	}
	this.list.onSelect = new Function(this.obj+'.select(); return false;')
	for (var i=0;i<this.list.items.length;i++) {
		if (this.list.items[i].hasChild) this.list.items[i].child.activate()
	}
}
function MenuListSelect() {
	var i = this.list.selectedIndex
	if (i!=null) {
		if (this.childShown==i) {
			this.hideMenu(this.childShown)
		} else {
			this.hideMenu()
			if (this.list.items[i].hasChild) this.showMenu(i)
			if (!this.list.items[i].hasChild || this.subOnSelect) this.onSelect()
		}
	}
}
function MenuListHideMenu() {
	var i = this.childShown
	if (i!=null && this.list.items[i]!=null) {
		this.childShown = null
		this.list.items[i].child.lyr.hide()
		this.list.items[i].child.hideMenu()
		if (this.list.items[i].child.list.selectedIndex!=null) {
			this.list.items[i].child.list.deselect(this.list.items[i].child.list.selectedIndex)
		}
		if (is.ns && !this.isChild) this.lyr.clipTo(0,this.w,this.h,0)
	}
}
function MenuListShowMenu(i) {
	if (is.ns && !this.isChild) this.lyr.clipTo(0,this.lyr.w,this.lyr.h,0)
	this.list.items[i].child.lyr.show()
	this.childShown = i
}
function MenuListToggle() {
	if (!loaded) return
	if (!this.visible) this.show()
	else this.hide()
}
function MenuListHide() {
	if (!loaded) return
	this.hideMenu()
	this.list.deselect(this.list.selectedIndex)
	this.lyr.hide()
	this.visible = false
}
function MenuListShow() {
	this.lyr.css.visibility = 'inherit'
	this.visible = true
}
function MenuListRedirect() {
	this.hide()
	location.href = this.list.value
}
MenuList.count = 0
