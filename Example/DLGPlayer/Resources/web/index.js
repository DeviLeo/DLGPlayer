///
///
///
var g_files = [];
var g_uploading_index = 0;

///
/// String in JS
///
var STRING_TITLE = "文件管理";
var STRING_MULTIPLE_FILE_SELECTION_UNSUPPORTED = "浏览器不支持选择多个文件。";
var STRING_UPLOADING_FAILED = "上传失败";
var STRING_UPLOADING_CANCELED = "上传已被取消";
var STRING_CONFIRM_DELETE_SELECTED_FILES = "确定要删除所选文件吗？";
var STRING_DELETE_ALL_FILES_FAILED = "部分文件未被删除";
var STRING_DELETE_FILE_FAILED = "无法删除:";
var STRING_FILE_ALREADY_EXISTS = "文件已经存在。是否覆盖？";

///
/// String in HTML
///
var TEXT_H1 = "文件管理";
var TEXT_UPLOADING_LIST = "上传列表";
var TEXT_FILENAME = "文件名";
var TEXT_SIZE = "大小";
var TEXT_UPLOADED = "已上传";
var TEXT_DELETE = "删除所选";
var TEXT_ADD = "添加文件";
var TEXT_UPLOAD = "开始上传";
var TEXT_DOCUMENTS_LIST = "文件列表";

///
///
///

function supportAjaxUploadWithProgress() {
	return supportFormData() && supportFileAPI() && supportAjaxUploadProgressEvent();
}

function supportFormData() {
	return !!window.FormData;
}
function supportAjaxUploadProgressEvent() {
	var xhr = new XMLHttpRequest();
	return  (xhr && ("upload" in xhr) && ("onprogress" in xhr.upload));
}
function supportFileAPI() {
	var input = document.createElement("input");
	input.type = "file";
	return "files" in input;
}

function localizeAllStrings() {
    var lang = navigator.language || navigator.userLanguage;
    lang = lang.split("-");
    var lang1 = lang[0].toLowerCase();
    var lang2 = lang1;
    if (lang.length > 1) {
        lang2 = lang[1].toLowerCase();
    }
    if (lang1 == "zh" && lang2 == "cn") {
        // default, nothing to change
    } else {
        ///
        STRING_TITLE = "File Management";
        STRING_MULTIPLE_FILE_SELECTION_UNSUPPORTED = "Your browser does not support multiple files selection.";
        STRING_UPLOADING_FAILED = "Uploading failed.";
        STRING_UPLOADING_CANCELED = "Uploading canceled.";
        STRING_CONFIRM_DELETE_SELECTED_FILES = "Are you sure delete selected files?";
        STRING_DELETE_ALL_FILES_FAILED = "Some files could not be deleted.";
        STRING_DELETE_FILE_FAILED = "Could not delete this file:";
		STRING_FILE_ALREADY_EXISTS = "File already exists. Overwrite?";
        
        ///
        TEXT_H1 = "File Management";
        TEXT_UPLOADING_LIST = "Uploading List";
        TEXT_FILENAME = "Filename";
        TEXT_SIZE = "Size";
        TEXT_UPLOADED = "Uploaded";
        TEXT_DELETE = "Delete";
        TEXT_ADD = "Add...";
        TEXT_UPLOAD = "Upload";
        TEXT_DOCUMENTS_LIST = "File List";
    }
}

function localize() {
    document.title = STRING_TITLE;
    document.getElementById("text_h1").innerHTML = TEXT_H1;
    document.getElementById("text_uploading_list").innerHTML = TEXT_UPLOADING_LIST;
    document.getElementById("text_uploading_filename").innerHTML = TEXT_FILENAME;
    document.getElementById("text_uploading_size").innerHTML = TEXT_SIZE;
    document.getElementById("text_uploading_uploaded").innerHTML = TEXT_UPLOADED;
    document.getElementById("uploading_delete_selected").value = TEXT_DELETE;
    document.getElementById("button_add").value = TEXT_ADD;
    document.getElementById("button_upload").value = TEXT_UPLOAD;
    document.getElementById("text_documents_list").innerHTML = TEXT_DOCUMENTS_LIST;
    document.getElementById("text_uploaded_filename").innerHTML = TEXT_FILENAME;
    document.getElementById("text_uploaded_size").innerHTML = TEXT_SIZE;
    document.getElementById("uploaded_delete_selected").value = TEXT_DELETE;
}

function onLoad() {
	// alert(navigator.sayswho);
    localizeAllStrings();
    localize();
    var uploader = document.getElementById("file_uploader");
	if (typeof(uploader.files) == "undefined") {
		alert(STRING_MULTIPLE_FILE_SELECTION_UNSUPPORTED);
	} else {
        var uploaded_files_table = document.getElementById("uploaded_files_table");
        var uploaded_select_all = document.getElementById("uploaded_select_all");
        if (uploaded_files_table.rows.length > 0) {
            uploaded_select_all.removeAttribute("disabled");
        } else {
            uploaded_select_all.setAttribute("disabled", "disabled");
        }
    }
}

navigator.sayswho= (function(){
    var ua= navigator.userAgent, 
    N= navigator.appName, tem, 
    M= ua.match(/(opera|chrome|safari|firefox|msie|trident)\/?\s*([\d\.]+)/i) || [];
    M= M[2]? [M[1], M[2]]:[N, navigator.appVersion, '-?'];
    if(M && (tem= ua.match(/version\/([\.\d]+)/i))!= null) M[2]= tem[1];
    return M.join(' ');
})();

function removeAllUploadingFiles() {
	var divUpload = document.getElementById("divUpload");
	var length = divUpload.childNodes.length;
	for (var i = 0; i < length; ++i) {
		var node = divUpload.childNodes[i];
		if (node.nodeType != Node.ELEMENT_NODE) continue;
		var nodeName = node.nodeName.toLowerCase();
		var attrType = node.getAttribute("type");
		if (nodeName != "input" && attrType != "file") continue;
		if (node.id == "file_uploader") continue;
		divUpload.removeChild(node);
		--length;--i;
	}
}

function uploadFiles() {

	// remove <input type="file"/>
	removeAllUploadingFiles();
	
	var button_upload = document.getElementById("button_upload");
	button_upload.setAttribute("disabled", "disabled");
	
	// ajax uploading
	if (supportAjaxUploadWithProgress()) {
		var length = g_files.length;
		if (g_uploading_index < length) {
			
			// check filename
			var file = g_files[g_uploading_index];
			var name = file.name;
            var uri = "/check?filename="+name;
            var xhr = new XMLHttpRequest();
            xhr.open("GET", uri, false);
            xhr.send();
            
            var canUpload = false;
			if (xhr.responseText == "1") {
				canUpload = true;
            } else  {
				var result = confirm(name+"\n"+STRING_FILE_ALREADY_EXISTS);
				if (result) {
					canUpload = true;
				} else {
					button_upload.removeAttribute("disabled");
				}
            }
            
            // upload
			if (canUpload) {
				var form_data = new FormData();
				form_data.append("file", g_files[g_uploading_index]);
				xhr = new XMLHttpRequest();
				xhr.upload.addEventListener("load", onUploadComplete, false);
				xhr.upload.addEventListener("error", onUploadFailed, false);
				xhr.upload.addEventListener("abort", onUploadCanceled, false);
				xhr.upload.addEventListener("progress", onUploadProgress, false);
				xhr.open("POST", "/upload", true);
				xhr.send(form_data);
			}
		}
	}
}

function onUploadProgress(event) {
	if (event.lengthComputable) {
		var uploading_files_table = document.getElementById("uploading_files_table");
		var row_length = uploading_files_table.rows.length;
		if (g_uploading_index < row_length) {
			var row = uploading_files_table.rows[g_uploading_index];
			var percent = event.loaded / event.total * 100;
			percent = percent.toFixed(0);
			row.childNodes[3].childNodes[0].nodeValue = percent + "%";
		}
	}
}

function onUploadComplete(event) {
	addUploadingToUploaded();
	var uploading_files_table = document.getElementById("uploading_files_table");
	var row = uploading_files_table.rows[g_uploading_index];
	row.childNodes[3].childNodes[0].nodeValue = "100%";
	++g_uploading_index;
	var length = g_files.length;
	if (g_uploading_index < length) {
		// check filename
		var file = g_files[g_uploading_index];
		var name = file.name;
        var uri = "/check?filename="+name;
        var xhr = new XMLHttpRequest();
        xhr.open("GET", uri, false);
        xhr.send();

        var canUpload = false;
		if (xhr.responseText == "1") {
			canUpload = true;
        } else  {
			var result = confirm(name+"\n"+STRING_FILE_ALREADY_EXISTS);
			if (result) {
				canUpload = true;
			} else {
				var button_upload = document.getElementById("button_upload");
				button_upload.removeAttribute("disabled");
			}
        }
                   
        // upload
		if (canUpload) {
			var form_data = new FormData();
			form_data.append("file", g_files[g_uploading_index]);
			xhr = new XMLHttpRequest();
			xhr.upload.addEventListener("load", onUploadComplete, false);
			xhr.upload.addEventListener("error", onUploadFailed, false);
			xhr.upload.addEventListener("abort", onUploadCanceled, false);
			xhr.upload.addEventListener("progress", onUploadProgress, false);
			xhr.open("POST", "/upload", true);
			xhr.send(form_data);
		}
	}
}
function onUploadFailed(event) {
	alert(STRING_UPLOADING_FAILED);
	var button_upload = document.getElementById("button_upload");
	button_upload.removeAttribute("disabled");
}
function onUploadCanceled(event) {
	alert(STRING_UPLOADING_CANCELED);
	var button_upload = document.getElementById("button_upload");
	button_upload.removeAttribute("disabled");
}
function addUploadingToUploaded() {
	var length = g_files.length;
	if (g_uploading_index < length) {
		var uploaded_files_table = document.getElementById("uploaded_files_table");
		var row_index = uploaded_files_table.rows.length;
		var style = "border-bottom-style:solid;border-bottom-color:#EEEEEE;border-bottom-width:1px;";
		var file = g_files[g_uploading_index];
		var name = file.name;
		var size = file.size;
		size = getComputerSizeString(size);
		
		// check filename
		var table = document.getElementById("uploaded_files_table");
		var length = table.rows.length;
		for (var i = 0; i < length; ++i) {
			var row = table.rows[i];
			var filename = row.childNodes[1].childNodes[0].childNodes[0].nodeValue;
			if (filename == name) {
				return;
			}
		}
		
		// index
		var checkbox_id = "uploaded_checkbox_" + row_index;
		var tr_id = "uploaded_tr_" + row_index;
		
		// create checkbox
		var checkbox = document.createElement("input");
		checkbox.setAttribute("id", checkbox_id);
		checkbox.setAttribute("type","checkbox");
		checkbox.setAttribute("value",name);
		checkbox.setAttribute("onchange", "onRowCheckboxClick(this)");
		
		// create td - checkbox
		var td_checkbox = document.createElement("td");
		td_checkbox.setAttribute("class", "uploaded_tr_0");
		td_checkbox.appendChild(checkbox);
		
		// create a
		var a = document.createElement("a");
		a.setAttribute("href", name);
		a.appendChild(document.createTextNode(name));
		
		// create td - filename
		var td_filename = document.createElement("td");
		td_filename.setAttribute("class", "uploaded_tr_1");
		td_filename.appendChild(a);
		
		// create td - size
		var td_size = document.createElement("td");
		td_size.setAttribute("class", "uploaded_tr_2");
		td_size.appendChild(document.createTextNode(size));
		
		// create tr
		var tr = document.createElement("tr");
		tr.setAttribute("id", tr_id);
		tr.setAttribute("style", style);
		tr.setAttribute("onclick", "onRowClick(this)");
		tr.appendChild(td_checkbox);
		tr.appendChild(td_filename);
		tr.appendChild(td_size);
		
		// append tr
		uploaded_files_table.appendChild(tr);
		
		var uploaded_select_all = document.getElementById("uploaded_select_all");
		if (uploaded_files_table.rows.length > 0) {
			uploaded_select_all.removeAttribute("disabled");
		} else {
			uploaded_select_all.setAttribute("disabled", "disabled");
		}
	}
}

function addFiles() {
	var file_uploader = document.getElementById("file_uploader");
	var new_file_uploader = file_uploader.cloneNode(true);
	new_file_uploader.id = "";
	file_uploader.parentNode.appendChild(new_file_uploader);
	new_file_uploader.click();
}
function getComputerSizeString(size) {
	var level = 0;
	while (size > 1024.00) {
		level++;
		size /= 1024;
		if (level >= 5) break;
	}
	size = size.toFixed(2);
	if (level == 0) size += "B";
	else if (level == 1) size += "K";
	else if (level == 2) size += "M";
	else if (level == 3) size += "G";
	else if (level == 4) size += "T";
	else if (level == 5) size += "P";
	return size;
}

function checkSelectAll(checkbox) {
	var splitString = checkbox.id.split("_");
	var isUploading = splitString[0] == "uploading";
	if (checkbox.checked) {
		var selectAll = document.getElementById(isUploading ? "uploading_select_all" : "uploaded_select_all");
		var table = document.getElementById(isUploading ? "uploading_files_table" : "uploaded_files_table");
		var length = table.rows.length;
		for (var i = 0; i < length; ++i) {
			var row = table.rows[i];
			var row_checkbox = row.childNodes[0].childNodes[0];
			if (row_checkbox.checked) {
				continue;
			} else {
				if (selectAll.checked) { selectAll.checked = false; }
				break;
			}
		}
		// All checked
		if (i == length && !selectAll.checked) {
			selectAll.checked = true;
		}
		var deleteSelected = document.getElementById(isUploading ? "uploading_delete_selected" : "uploaded_delete_selected");
		deleteSelected.removeAttribute("disabled");
	} else {
		var selectAll = document.getElementById(isUploading ? "uploading_select_all" : "uploaded_select_all");
		if (selectAll.checked) { selectAll.checked = false; }
		
		// check did deselect all
		var table = document.getElementById(isUploading ? "uploading_files_table" : "uploaded_files_table");
		var length = table.rows.length;
		for (var i = 0; i < length; ++i) {
			var row = table.rows[i];
			var row_checkbox = row.childNodes[0].childNodes[0];
			if (!row_checkbox.checked) {
				continue;
			} else {
				if (selectAll.checked) { selectAll.checked = false; }
				break;
			}
		}
		// All unchecked
		if (i == length) {
			var deleteSelected = document.getElementById(isUploading ? "uploading_delete_selected" : "uploaded_delete_selected");
			deleteSelected.setAttribute("disabled", "disabled");
		}
	}
}

function onRowClick(row) {
	var checkbox = row.childNodes[0].childNodes[0];
	checkbox.checked = !checkbox.checked;
	var style = "border-bottom-style:solid;border-bottom-color:#EEEEEE;border-bottom-width:1px;";
	var color = checkbox.checked ? "background-color:#80D0FF;" : "background-color:white;";
	row.setAttribute("style", style+color);
	checkSelectAll(checkbox);
}

function onAddFiles(sender) {
	var uploading_files_table = document.getElementById("uploading_files_table");
	var row_index = uploading_files_table.rows.length;
	var files = sender.files;
	for (var i = 0; i < files.length; i++) {
		// index
		var index = row_index+i;
		
		// file attribute
		var file = files[i];
		var name = file.name;
		var size = file.size;
		size = getComputerSizeString(size);
		
		// create checkbox
		var checkbox = document.createElement("input");
		var checkbox_id = "uploading_checkbox_" + index;
		checkbox.setAttribute("id", checkbox_id);
		checkbox.setAttribute("type","checkbox");
		checkbox.setAttribute("value",name);
		checkbox.setAttribute("onchange", "onRowCheckboxClick(this)");
		
		// create td - checkbox
		var td_checkbox = document.createElement("td");
		td_checkbox.setAttribute("class", "uploading_tr_0");
		td_checkbox.appendChild(checkbox);
		
		// create td - filename
		var td_filename = document.createElement("td");
		td_filename.setAttribute("class", "uploading_tr_1");
		td_filename.appendChild(document.createTextNode(name));
		
		// create td - size
		var td_size = document.createElement("td");
		td_size.setAttribute("class", "uploading_tr_2");
		td_size.appendChild(document.createTextNode(size));
		
		// create td - upload percent
		var td_percent = document.createElement("td");
		td_percent.setAttribute("class", "uploading_tr_3");
		td_percent.appendChild(document.createTextNode("0%"));
		
		// create tr
		var tr = document.createElement("tr");
		var tr_id = "uploading_tr_" + index;
		tr.setAttribute("id", tr_id);
		tr.setAttribute("onclick", "onRowClick(this)");
		tr.setAttribute("style", "border-bottom-style:solid;border-bottom-color:#EEEEEE;border-bottom-width:1px;");
		tr.appendChild(td_checkbox);
		tr.appendChild(td_filename);
		tr.appendChild(td_size);
		tr.appendChild(td_percent);
		
		// append tr
		uploading_files_table.appendChild(tr);
		g_files.push(file);
	}
	var uploading_select_all = document.getElementById("uploading_select_all");
	var button_upload = document.getElementById("button_upload");
	if (uploading_files_table.rows.length > 0) {
		uploading_select_all.removeAttribute("disabled");
		button_upload.removeAttribute("disabled");
	} else {
		uploading_select_all.setAttribute("disabled", "disabled");
		button_upload.setAttribute("disabled", "disabled");
	}
}

function onSelectAllChange(sender) {
	var splitString = sender.id.split("_");
	var isUploading = splitString[0] == "uploading";
	
	var table = document.getElementById(isUploading ? "uploading_files_table" : "uploaded_files_table");
	var length = table.rows.length;
	var style = "border-bottom-style:solid;border-bottom-color:#EEEEEE;border-bottom-width:1px;";
	var checked_color = style+"background-color:#80D0FF;";
	for (var i = 0; i < length; i++) {
		var row = table.rows[i];
		var checkbox = row.childNodes[0].childNodes[0];
		if (checkbox.checked != sender.checked) {
			checkbox.checked = sender.checked;
			var color = checkbox.checked ? checked_color : style;
			row.setAttribute("style", color);
		}
	}
	
	var deleteSelected = document.getElementById(isUploading ? "uploading_delete_selected" : "uploaded_delete_selected");
	if (sender.checked) {
		deleteSelected.removeAttribute("disabled");
	} else {
		deleteSelected.setAttribute("disabled", "disabled");
	}
}

function onRowCheckboxClick(checkbox) {
	var row = checkbox.parentNode.parentNode;
	checkbox.checked = !checkbox.checked;
	var style = "border-bottom-style:solid;border-bottom-color:#EEEEEE;border-bottom-width:1px;";
	var color = checkbox.checked ? "background-color:#80D0FF;" : "background-color:white;";
	row.setAttribute("style", style+color);
	checkSelectAll(checkbox);
}

function deleteSelectedFiles(sender) {
	var result = confirm(STRING_CONFIRM_DELETE_SELECTED_FILES);
	if (result) {
		var splitString = sender.id.split("_");
		var isUploading = splitString[0] == "uploading";
		var table = document.getElementById(isUploading ? "uploading_files_table" : "uploaded_files_table");
		var selectAll = document.getElementById(isUploading ? "uploading_select_all" : "uploaded_select_all");
		if (selectAll.checked) {
			if (isUploading) {
				g_files = [];
				g_uploading_index = 0;
				var button_upload = document.getElementById("button_upload");
				button_upload.setAttribute("disabled", "disabled");
                while (table.hasChildNodes()) {
                    table.removeChild(table.lastChild);
                }
                selectAll.checked = false;
                selectAll.setAttribute("disabled", "disabled");
			} else {
                var uri = "/deleteAllFiles";
                var xhr = new XMLHttpRequest();
                xhr.open("GET", uri, false);
                xhr.send();
                if (xhr.responseText == "0") {
                    alert(STRING_DELETE_ALL_FILES_FAILED);
                } else  {
                    while (table.hasChildNodes()) {
                        table.removeChild(table.lastChild);
                    }
                    selectAll.checked = false;
                    selectAll.setAttribute("disabled", "disabled");
                }
            }
		} else {
			var length = table.rows.length;
			var rows = [];
			for (var i = 0; i < length; ++i) {
				var row = table.rows[i];
				var checkbox = row.childNodes[0].childNodes[0];
				if (checkbox.checked) {
					if (isUploading) {
						var count = g_files.length;
						if (i < count) {
							if (i < g_uploading_index && g_uploading_index > 0) {
								--g_uploading_index;
							}
							g_files.splice(i, 1);
						}
                        table.removeChild(row);
                        --length; --i;
					} else {
                        var name = row.childNodes[1].childNodes[0].childNodes[0].nodeValue;
                        var uri = "/delete?file="+name;
                        var xhr = new XMLHttpRequest();
                        xhr.open("GET", uri, false);
                        xhr.send();
                        if (xhr.responseText == "1") {
                            row.parentNode.removeChild(row);
                            --length; --i;
                        } else  {
                            alert(STRING_DELETE_FILE_FAILED+name);
                        }
                    }
				}
			}
		}
		sender.setAttribute("disabled", "disabled");
	}
}
