// List Object
// generic selection widget built primarily to be incorporated into other List-based widgets (MenuList, ScrollList, SelectList)
// 19990410

// Copyright (C) 1999 Dan Steinman
// Distributed under the terms of the GNU Library General Public License
// Available at http://www.dansteinman.com/dynapi/

// Thanks to: Knut Dale <Knut.S.Dale@eto.ericsson.se>

function List(x,y,width,itemH) {
	this.name = "List"+(List.count++)
	this.x = x
	this.y = y
	this.w = width
	if (arguments.length==4) {
		this.itemH = itemH
		this.itemHset = true
		this.h = -1
	}
	else {
		this.itemH = null
		this.itemHset = false
		this.h = (is.ns)? -1 : 1000
	}

	this.itemSpacing = 1
	this.fontname = fontName // set in /widgets/wrappers/xxx/header.mc
	this.fontsize = fontSize // set in /widgets/wrappers/xxx/header.mc
	this.visibility = 'inherit'

	this.overOpen = false
	this.menulist = null
	this.indent = 1
	
	this.color = new Object()
	this.color.textNormal = '#000000'
	this.color.textSelected = '#FF3300'
	this.color.bgNormal = '#FFFFFF'
	this.color.bgSelected = '#FFFFFF'
	this.color.bgRollover = '#FFFFCC'
	this.color.bg = '#cccccc'

	this.allowDeselect = false
	this.multiSelect = false
	this.preSelect = null

	this.items = new Array()
	this.selectedIndex = null
	this.obj = this.name + "ListObject"
	eval(this.obj + "=this")

	this.add = ListAdd
	this.build = ListBuild
	this.activate = ListActivate
	this.over = ListOver
	this.out = ListOut
	this.down = ListDown
	this.select = ListSelect
	this.setCols = ListSetCols
	this.image = new Object()
	this.setImage = ListSetImage
	this.deselect = ListDeselect
	this.onSelect = new Function()
}
function ListSetCols() {
	this.cols = arguments
	this.multiCol = true
}
function ListSetImage(image0,image1,width,height) {
	this.image.image0 = new Image()
	this.image.image0.src = image0
	this.image.image1 = new Image()
	this.image.image1.src = image1
	this.image.w = width
	this.image.h = height
}
function ListAdd(value) {
	var i = this.items.length
	this.items[i] = new Array()
	this.items[i].selected = false
	this.items[i].value = value
	if (arguments.length>2) {
		this.items[i].textNormal = this.items[i].textSelected = '<table border=0 cellpadding=0 cellspacing=0><tr>'
		this.items[i].text = new Array()
		for (var j=1;j<arguments.length;j++) {
			this.items[i].text[j-1] = ''+arguments[j]
			this.items[i].textNormal += '<td width='+this.cols[j-1]+'><div class="'+this.name+'TextNormal">'+arguments[j]+'</div></td>'
			this.items[i].textSelected += '<td width='+this.cols[j-1]+'><div class="'+this.name+'TextSelected">'+arguments[j]+'</div></td>'
		}
		this.items[i].textNormal += '</tr></table>'
		this.items[i].textSelected += '</tr></table>'
	}
	else {
		this.items[i].text = arguments[1]
		this.items[i].textNormal = '<div class="'+this.name+'TextNormal">'+arguments[1]+'</div>'
		this.items[i].textSelected = '<div class="'+this.name+'TextSelected">'+arguments[1]+'</div>'
	}
	if (this.itemH) {
		this.h += this.itemH+this.itemSpacing
		this.items[i].y = i*this.itemH+i*this.itemSpacing
	}
	else this.items[i].y = 0
}
function ListBuild() {
	this.css = ''
	this.css += css(this.name+'List',this.x,this.y,this.w,this.h,this.color.bg,(this.itemHset)?this.visibility:'hidden')
	for (var i=0;i<this.items.length;i++) {
		this.css += css(this.name+'ListItem'+i,0,this.items[i].y,this.w,this.itemH,this.color.bgNormal)
		if (this.items[i].hasImage) this.css += css(this.name+'ListItemImgLyr'+i,this.w-this.image.w,this.items[i].y)
		this.css += css(this.name+'ListItemC'+i,0,this.items[i].y,this.w,this.itemH)
	}
	this.css += '.'+this.name+'TextNormal {font-family:"'+this.fontname+'"; font-size:'+this.fontsize+'pt; color:'+this.color.textNormal+'; background-color:transparent; margin-left:'+this.indent+'px;}\n'+
	'.'+this.name+'TextSelected {font-family:"'+this.fontname+'"; font-size:'+this.fontsize+'pt; color:'+this.color.textSelected+'; background-color:transparent; margin-left:'+this.indent+'px;}\n'

	this.div = '<div id="'+this.name+'List">\n'
	for (var i=0;i<this.items.length;i++) {
		this.div += '<div id="'+this.name+'ListItem'+i+'">'+this.items[i].textNormal+'</div>\n'
		if (this.items[i].hasImage) this.div += '<div id="'+this.name+'ListItemImgLyr'+i+'"><img name="'+this.name+'ListItemImg'+i+'" src="'+this.image.image0.src+'" width='+this.image.w+' height='+this.image.h+'></div>\n'
		this.div += '<div id="'+this.name+'ListItemC'+i+'"></div>\n'
	}
	this.div += '</div>'
}
function ListActivate() {
	if (is.ie) this.h -= 1001
	this.lyr = new DynLayer(this.name+'List')
	this.lyr.clipInit()

	for (var i=0;i<this.items.length;i++) {
		this.items[i].lyr = new DynLayer(this.name+'ListItem'+i)
		this.items[i].lyr.setbg = DynLayerSetbg
		this.items[i].lyre = new DynLayer(this.name+'ListItemC'+i)
		if (is.ns) this.items[i].lyre.event.captureEvents(Event.MOUSEDOWN)
		this.items[i].lyre.event.onmouseover = new Function(this.obj+'.over('+i+'); return false;')
		this.items[i].lyre.event.onmouseout = new Function(this.obj+'.out('+i+'); return false;')
		this.items[i].lyre.event.onmousedown = new Function(this.obj+'.down('+i+'); return false;')
		if (!this.itemHset) {
			this.itemH = (is.ns)? this.items[0].lyr.doc.height : this.items[0].lyr.event.offsetHeight
			this.items[i].lyr.moveTo(null,i*this.itemH+this.itemSpacing*i)
			this.items[i].lyre.moveTo(null,i*this.itemH+this.itemSpacing*i)
			if (is.ns) {
				this.items[i].lyr.clipInit()
				this.items[i].lyr.clipTo(0,this.w,this.itemH,0)
				this.items[i].lyre.clipInit()
				this.items[i].lyre.clipTo(0,this.w,this.itemH,0)
			}
			this.h += this.itemH+this.itemSpacing
		}
		if (this.items[i].hasImage) {
			this.items[i].imagelyr = new DynLayer(this.name+'ListItemImgLyr'+i)
		}
	}
	if (!this.itemHset) {
		this.lyr.clipTo(0,this.w,this.h,0)
		if (is.ie) this.lyr.css.height = this.h
	}
	if (this.preSelect!=null) this.select(this.preSelect)
	this.lyr.css.visibility = this.visibility
}
function ListOver(i) {
	if (!this.items[i].selected) {
	   this.items[i].lyr.setbg(this.color.bgRollover)
	}
	if (this.overOpen && i!=this.selectedIndex) {
		this.menulist.hideMenu()
		this.deselect(this.selectedIndex)
		if (this.items[i].hasChild) this.select(i)
	}
}
function ListOut(i) {
	if (!this.items[i].selected) this.items[i].lyr.setbg(this.color.bgNormal)
}
function ListDown(i) {
	if (!this.items[i].selected) {
		if (!this.multiSelect && this.selectedIndex!=null) this.deselect(this.selectedIndex)
		this.select(i)		
	}
	else {
		if (this.multiSelect || this.allowDeselect) {
			this.menulist.hideMenu()
			this.deselect(i)
		}
	}
}
function ListSelect(i) {
	if (this.items[i]!=null) {	
		this.selectedIndex = i
		this.value = this.items[i].value
		if (this.items[i].hasImage) this.items[i].imagelyr.doc.images[this.name+'ListItemImg'+i].src = this.image.image1.src
		this.items[i].lyr.setbg(this.color.bgSelected)
		this.items[i].lyr.write(this.items[i].textSelected)
		this.items[i].selected = true
		this.onSelect()
	}
}

function ListDeselect(i) {
	if (this.items[i]!=null) {
	   if (this.items[i].selected) {
		if (this.items[i].hasImage) this.items[i].imagelyr.doc.images[this.name+'ListItemImg'+i].src = this.image.image0.src
		this.items[i].lyr.setbg(this.color.bgNormal)
		this.items[i].lyr.write(this.items[i].textNormal)
		this.items[i].selected = false
		if (!this.multiSelect) this.selectedIndex = null
	   }
	}
}
function ListRedirect() {
	location.href = this.value
}
List.count = 0

// Dynlayer setbg() required
function DynLayerSetbg(color) {
	if (is.ns) this.doc.bgColor = color
	else if (is.ie) this.css.backgroundColor = color
}

