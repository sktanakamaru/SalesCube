<%@page pageEncoding="UTF-8" %>
<%@page import="jp.co.arkinfosys.common.Constants" %>
<%@page import="jp.co.arkinfosys.common.CategoryTrns" %>
<%@page import="jp.co.arkinfosys.form.AbstractSlipEditForm"%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html lang="ja">
<head>
	<title><bean:message key='titles.system'/> <bean:message key='titles.poInput'/></title>
	<%@ include file="/WEB-INF/view/common/header.jsp" %>

<script type="text/javascript">
<!--

/*******************************************************************************
 * 定数宣言
 ******************************************************************************/
var MAX_LINE_ROW_COUNT = <%= AbstractSlipEditForm.MAX_LINE_SIZE %>;
//メインフォームの名前
var MainFormName = "porder_inputPOrderActionForm";
//メインフォームのデフォルトのアクション保持用
var MainDefaultAction;
var maxIndex = 0;
// 明細行の確保領域
var trCloneBase = null;
var trCloneBaseIndex = 0;

var changeFlag = false;

//仕入先・商品コードの存在
var CODE_NOEXIST = 0;
var CODE_EXIST = 1;

//税転嫁
var taxShiftCategorySlipTotal = "<%=CategoryTrns.TAX_SHIFT_CATEGORY_SLIP_TOTAL%>";
var taxShiftCategoryCloseTheBooks = "<%=CategoryTrns.TAX_SHIFT_CATEGORY_CLOSE_THE_BOOKS%>";



/*******************************************************************************
 * 送信・表示制御
 ******************************************************************************/

//ロード時の関数読込み
window.onload = init;


//フォームのアクションをいじってからサブミットする。
function ActionSubmit(FormName,DefaultActionName,ActionName){
	showNowSearchingDiv();
	$("form[name='" + FormName + "']").attr("action",DefaultActionName + ActionName);
	$("form[name='" + FormName + "']").submit();
	$("form[name='" + FormName + "']").attr("action",DefaultActionName);
}

//単価・金額の必須表示
function changeMustStatus(){
	var l_rateId = oBDCS($("#rateId").val());
	if(!l_rateId.isNum()){
		$("span.dolMust").css("display","none");
		$("span.yenMust").css("display","");
	}else{
		$("span.dolMust").css("display","");
		$("span.yenMust").css("display","none");
	}
}

//ページ読込時の動作
function init() {

	//デフォルトアクションの取得
	MainDefaultAction = $("form[name='" + MainFormName + "']").attr("action");

	//数量入力欄の挙動追加
	var targetQua = $("input[type='text'][id^='quantity_']");
	if (targetQua.size() > 0) {
		targetQua.focus(quantity_focus);
		targetQua.blur(quantity_blur);
	}

	// 明細行のIndex管理
	var tBodyLine = $("#tbodyLine");
	maxIndex = tBodyLine.children().size() - 1;

	//敬称プルダウンのバックアップ
	BackupSupplierPcPreCategoryList();
	//敬称プルダウン設定
	supplierPcPreCategoryListCtrl(${supplierPcPreCategory});

	//行削除Buttonの制御
	delAndCopyButtonDisabledControl();

	//リスト初期化
	pseudoSyncAjaxFunctionList.length = 0;
	//桁適用
	pseudoSyncAjaxFunctionList.push(BDCsettingOnLoad);
	//レートと税率の取得
	pseudoSyncAjaxFunctionList.push(GetSupplierRateOnLoad);
	pseudoSyncAjaxFunctionList.push(GetSupplierTaxRateOnLoad);
	//伝票合計の計算
	pseudoSyncAjaxFunctionList.push(sumPricesOnLoad);
	//リクエスト
	pseudoSyncRequest();

	//初期フォーカス
//	$("#poDate").focus();
	if( $("#poSlipId").val() != "" ){
		$("#poSlipId").attr("readOnly", "true");
		$("#poSlipId").addClass("c_disable");
		$("#poDate").focus();
	}else{
		$("#poSlipId").focus();
	}
	$("input[type='text']").add("input[type='checkbox']:not('.dummy')").add("select").add("textarea").bind("change", changeOn );

	$("#customerCode").attr("maxlength", <%=Constants.CODE_SIZE.CUSTOMER%>);	//顧客コードの文字数制限10桁

	// 明細行のクローンを生成
	trCloneBase = tBodyLine.children(":first").clone(true);

	var match = trCloneBase.attr("id").match(/^row_([0-9]+)$/);
	if( match ) {
		trCloneBaseIndex = parseInt( match[1] );
	}

	trCloneBase.find("input[type='hidden']").val("");
	trCloneBase.find("input[type='text']").val("");
	trCloneBase.find("textarea").text("");
	trCloneBase.find("span").html("");
	trCloneBase.find("select").each(
			function() {
				this.selectedIndex = 0;
			}
	);
	for(var i=0; i<=maxIndex; i++) {
		setLineEvent( i );
	}

	//必須表示の変更
	changeMustStatus();

	// 行ステータスに応じた入力制限
	changeLineStatusView();
}

function id2line(id){
	return $("#poLineNo_"+id).val();
}

function line2id(line){
	trId = $("#tbodyLine").get(0).children[line].id;
	id = trId.replace("row_", "");
	return id;
}

function changeOn(){
	changeFlag = true;
}

function enableSendLines(){
	for (var RowNum = 0; RowNum < $("#tbodyLine").get(0).children.length ; RowNum++){
		id = line2id(RowNum);
		$("#lineDeliveryDate_"+id).datepicker("enable");
	}
}

function changeLineStatusView(){
	for (var RowNum = 0; RowNum < $("#tbodyLine").get(0).children.length; RowNum++){
		id = line2id(RowNum);
		changeLineStatusLineView(id);
	}
}
function changeLineStatusLineView(no){
	var id = line2id(no);

	if( $("#lineStatus_"+id).val() == <%= Constants.STATUS_PORDER_LINE.ORDERED %> ){
		// 未納
		$("#productCode_"+id).attr("readonly", false);
		$("#productCode_"+id).removeClass("c_disable");
		$("#supplierPcode_"+id).attr("readonly", false);
		$("#supplierPcode_"+id).removeClass("c_disable");
		$("#quantity_"+id).attr("readonly", false);
		$("#quantity_"+id).removeClass("c_disable");
		$("#unitPrice_"+id).attr("readonly", false);
		$("#unitPrice_"+id).removeClass("c_disable");
		$("#price_"+id).attr("readonly", false);
		$("#price_"+id).removeClass("c_disable");
		$("#ctaxPrice_"+id).attr("readonly", false);
		$("#ctaxPrice_"+id).removeClass("c_disable");
		$("#dolUnitPrice_"+id).attr("readonly", false);
		$("#dolUnitPrice_"+id).removeClass("c_disable");
		$("#dolPrice_"+id).attr("readonly", false);
		$("#dolPrice_"+id).removeClass("c_disable");
		$("#lineRemarks_"+id).attr("readonly", false);
		$("#lineRemarks_"+id).removeClass("c_disable");
		$("#lineDeliveryDate_"+id).datepicker("enable");
		$("#copyButton_"+id).attr("disabled", false);
		$("#delButton_"+id).attr("disabled", false);
		delAndCopyButtonDisabledControl();
	}else{
		// それ以外
		$("#productCode_"+id).attr("readonly", true);
		$("#productCode_"+id).addClass("c_disable");
		$("#supplierPcode_"+id).attr("readonly", true);
		$("#supplierPcode_"+id).addClass("c_disable");
		if( $("#lineStatus_"+id).val() == <%= Constants.STATUS_PORDER_LINE.NOWPURCHASING %> ){
			$("#quantity_"+id).attr("readonly", false);
			$("#quantity_"+id).removeClass("c_disable");
		}else{
			$("#quantity_"+id).attr("readonly", true);
			$("#quantity_"+id).addClass("c_disable");
		}
		$("#unitPrice_"+id).attr("readonly", true);
		$("#unitPrice_"+id).addClass("c_disable");
		$("#price_"+id).attr("readonly", true);
		$("#price_"+id).addClass("c_disable");
		$("#ctaxPrice_"+id).attr("readonly", true);
		$("#ctaxPrice_"+id).addClass("c_disable");
		$("#dolUnitPrice_"+id).attr("readonly", true);
		$("#dolUnitPrice_"+id).addClass("c_disable");
		$("#dolPrice_"+id).attr("readonly", true);
		$("#dolPrice_"+id).addClass("c_disable");
		if( $("#lineStatus_"+id).val() == <%= Constants.STATUS_PORDER_LINE.PURCHASED %> ){
			// 仕入完了
			$("#lineRemarks_"+id).attr("readonly", true);
			$("#lineRemarks_"+id).addClass("c_disable");
			$("#lineDeliveryDate_"+id).datepicker("disable");
		}else{
			$("#lineRemarks_"+id).attr("readonly", false);
			$("#lineRemarks_"+id).removeClass("c_disable");
			$("#lineDeliveryDate_"+id).datepicker("enable");
		}
		$("#copyButton_"+id).attr("disabled", true);
		$("#delButton_"+id).attr("disabled", true);
		delAndCopyButtonDisabledControl();
	}
}

function findSlip(){
	if( $("#poSlipId").val() == "" ){
	}else{
		showNowSearchingDiv();
		ActionSubmit(MainFormName,MainDefaultAction,"load");
	}
}

/*******************************************************************************
 * ファンクションキー制御
 ******************************************************************************/

//初期化機能
function onF1(){
	if(confirm("<bean:message key='confirm.init'/>")){

		// 常に新規状態にする
		showNowSearchingDiv();
		ActionSubmit(MainFormName,MainDefaultAction,"");
		$("#poSlipId").focus();

	}
}

<c:if test="${!newData}">
<c:if test="${!lockMode}">
//削除機能呼び出し
function onF2(){
	if(confirm("<bean:message key='confirm.delete'/>")){
		ActionSubmit(MainFormName,MainDefaultAction,"delete");
	}
}
//更新機能呼び出し
function onF3(){
	if(confirm("<bean:message key='confirm.update'/>")){
		$(".numeral_commas").rmvBDC();
		$(".BDC").rmvBDC();
		enableSendLines();
		ActionSubmit(MainFormName,MainDefaultAction,"upsert");
	}
}
</c:if>

//PDF出力機能
function onF4(){
	if(changeFlag){
		alert("<bean:message key='infos.valid.print' arg0='PDF'/>");
		return;
	}
	if(!confirm('<bean:message key="confirm.pdf" />')){return;}

	//IDリストを取得
	var form = $(window.document.forms["PDFOutputForm"]);
	var hidden = $(document.createElement("input"));
	hidden.attr("type", "hidden");
	hidden.attr("name", "slipIdList");
	hidden.val("${f:h(poSlipId)}");
	form.append(hidden);
	form.submit();
}


</c:if>

<c:if test="${newData && !lockMode}">
//登録機能呼び出し
function onF3(){
	if(confirm("<bean:message key='confirm.insert'/>")){
		$(".numeral_commas").rmvBDC();
		$(".BDC").rmvBDC();
		ActionSubmit(MainFormName,MainDefaultAction,"upsert");
	}
}
</c:if>

<c:if test="${!lockMode}">
//伝票複写
function onF6(){
	openCopySlipDialog('0700', 'copySlipFrom0700', copySlipCallback);
}
function copySlipCallback(dialogId, slipName, slipId){
	if(confirm("<bean:message key='confirm.copyslip'/>")){
		ActionSubmit(MainFormName,MainDefaultAction,"copy/"+slipId);
	}
}
</c:if>

/*******************************************************************************
 * 仕入先情報検索・設定 (仕入先コード、仕入先情報（敬称を含む）)
 ******************************************************************************/

//仕入先コード変更
 function ChangeSupplierCode(){
 	pseudoSyncAjaxFunctionList.length = 0;
 	//仕入先情報取得
 	pseudoSyncAjaxFunctionList.push(GetSupplierInfos);
 	//レートを取得
 	pseudoSyncAjaxFunctionList.push(GetSupplierRate);
 	//税率取得
 	pseudoSyncAjaxFunctionList.push(GetSupplierTaxRate);
 	//レート・税率変更に伴う再計算
 	pseudoSyncAjaxFunctionList.push(ChangeSupplierRateAndTaxRate);
 	pseudoSyncRequest();
 }

//仕入先検索ダイアログ呼び出し
function supplierSearch(){
	openSearchSupplierDialog( 'supplier' , function(openID,data){
		$("#supplierCode").attr("value",data.supplierCode);
		pseudoSyncAjaxFunctionList.length = 0;
		//仕入先情報の取得
		pseudoSyncAjaxFunctionList.push(GetSupplierInfos);
		//レート設定
		pseudoSyncAjaxFunctionList.push(GetSupplierRate);
		//税率設定
		pseudoSyncAjaxFunctionList.push(GetSupplierTaxRate);
	 	//レート・税率変更に伴う再計算
	 	pseudoSyncAjaxFunctionList.push(ChangeSupplierRateAndTaxRate);
		pseudoSyncRequest();
	});

	$("#supplier_supplierCode").attr("value",$("#supplierCode").attr("value"));

}

//仕入先情報の取得
function GetSupplierInfos(){
	if($("#supplierCode").attr("value")==""){
		InitSupplierInfos();
	}else{
		var data = new Object();
		data["tempSupplierCode"] = $("#supplierCode").attr("value");
		pseudoSyncRequestElement(
				contextRoot + "/ajax/commonPOrder/getSupplierInfosByPost/",
				data,
				function(data) {
					if(data==""){
						var ProductCodeLabel = '<bean:message key="labels.supplierCode" />';
						alert('<bean:message key="errors.notExist" arg0="'+ProductCodeLabel+'" />');
						InitSupplierInfos();
					}else{
						var value = eval("(" + data + ")");
						SetSupplierInfosToFroms(value);
					}
				}
				,null
				);
	}
}

//仕入先情報フォームIDリスト
var SupplierInfosIDList = new Array(
		"supplierIsExist",
		"supplierName",
		"supplierKana",
		"supplierZipCode",
		"supplierAddress1",
		"supplierAddress2",
		"supplierPcName",
		"supplierPcKana",
//		"supplierPcPreCategory",
		"supplierPcPost",
		"supplierTel",
		"supplierFax",
		"supplierEmail",
		"supplierAbbr",
		"supplierDeptName",
		"supplierPcPre",

		"taxFractCategory",
		"priceFractCategory",
		"unitPriceDecAlignment",
		"dolUnitPriceDecAlignment",
		"taxPriceDecAlignment",

		"rateId",
		"taxShiftCategory"
);

//仕入先情報設定(初期化)
function InitSupplierInfos(){
	for(var i in SupplierInfosIDList){
		$("#"+ SupplierInfosIDList[i]).attr("value","");
	}
	$("#supplierIsExist").attr("value",CODE_NOEXIST);
	//敬称
	supplierPcPreCategoryListCtrl("-1");
	//端数処理
	defaultBDCsettingForPrice();
}

//仕入先情報設定(確定した情報のセット以外には使わないでね。supplierIsExistもセットしちゃうから・・・)
function SetSupplierInfosToFroms(value){
	$("#supplierIsExist").attr("value",CODE_EXIST);
	$("#supplierName").attr("value",value.supplierName);
	$("#supplierKana").attr("value",value.supplierKana);
	$("#supplierZipCode").attr("value",value.supplierZipCode);
	$("#supplierAddress1").attr("value",value.supplierAddress1);
	$("#supplierAddress2").attr("value",value.supplierAddress2);
	$("#supplierPcName").attr("value",value.supplierPcName);
	$("#supplierPcKana").attr("value",value.supplierPcKana);
	$("#supplierPcPost").attr("value",value.supplierPcPost);
	$("#supplierTel").attr("value",value.supplierTel);
	$("#supplierFax").attr("value",value.supplierFax);
	$("#supplierEmail").attr("value",value.supplierEmail);
	$("#supplierAbbr").attr("value",value.supplierAbbr);
	$("#supplierDeptName").attr("value",value.supplierDeptName);
	$("#supplierPcPre").attr("value",value.supplierPcPre);

	$("#taxFractCategory").attr("value",value.taxFractCategory);
	$("#taxPriceDecAlignment").attr("value",value.taxPriceDecAlignment);

	$("#priceFractCategory").attr("value",value.priceFractCategory);
	$("#unitPriceDecAlignment").attr("value",value.unitPriceDecAlignment);
	$("#dolUnitPriceDecAlignment").attr("value",value.dolUnitPriceDecAlignment);

	$("#rateId").attr("value",value.rateId);
	//必須表示の変更
	changeMustStatus();
	$("#taxShiftCategory").attr("value",value.taxShiftCategory);

	CurrencyUnitClassNameHashList['dollar_value'] = value.cUnitSign;
	$("#defaultCUnit").val(CurrencyUnitClassNameHashList['dollar_value']);
	applyBDCsettingForPrice();

	supplierPcPreCategoryListCtrl(value.supplierPcPreCategory);
}

//敬称プルダウンのバックアップ
function BackupSupplierPcPreCategoryList() {
	$("body").append("<select style='display:none' id='supplierPcPreCategoryBackup'></select>");
	$('#supplierPcPreCategoryBackup').html($("#supplierPcPreCategory option").clone());
}

//敬称の絞込み
function supplierPcPreCategoryListCtrl(value){
	$("#supplierPcPreCategory").html($("#supplierPcPreCategoryBackup option").clone());
	$("#supplierPcPreCategory option").each(function(i){
		if((Number($(this).attr("value")) != -1)
				&& (Number($(this).attr("value"))!=Number(value))){$(this).remove();}
	});
	if ($("#supplierPcPreCategory option").length > 1){
		$("#supplierPcPreCategory option[value='-1']").remove();
	}
}

/*******************************************************************************
 * レート・税率取得
 ******************************************************************************/

function GetSupplierRateOnLoad(){
	//レートIDが有効なのにレートが無いなら
	var l_rateId = oBDCS($("#rateId").val());
	if(l_rateId.isNum() && ($("#supplierRate").attr("value") == "")){
		GetSupplierRate();
	}
}
function GetSupplierTaxRateOnLoad(){
	//レートIDが無く、税転嫁が指定範囲内なのに、税率が無いなら
	var l_rateId = oBDCS($("#rateId").val());
	if( ( ($("#taxShiftCategory").val() == taxShiftCategorySlipTotal) ||
	      ($("#taxShiftCategory").val() == taxShiftCategoryCloseTheBooks) ) &&
	    (!l_rateId.isNum()) ){
		GetSupplierTaxRate();
	}
}

//レートの取得
function GetSupplierRate(){
	if( ( $("#supplierCode").attr("value") == "" )
			|| ($("#supplierIsExist").attr("value") == CODE_NOEXIST)
			|| ( $("#poDate").attr("value") == "" ) ){
		$("#supplierRate").attr("value","");
	}else{
		var data = new Object();
		data["tempSupplierCode"] = $("#supplierCode").attr("value");
		data["targetDate"] = $("#poDate").attr("value");
		pseudoSyncRequestElement(
				contextRoot + "/ajax/commonPOrder/getSupplierRate/",
				data,
				function(result) {
					$("#supplierRate").attr("value",result);
				},
				null
		);
	}
}

//税率の取得
function GetSupplierTaxRate(){
	if( ( $("#supplierCode").attr("value") == "" )
			|| ($("#supplierIsExist").attr("value") == CODE_NOEXIST)
			|| ( $("#poDate").attr("value") == "" ) ){
		$("#supplierTaxRate").attr("value","");
	}else{
		var data = new Object();
		data["tempSupplierCode"] = $("#supplierCode").attr("value");
		data["targetDate"] = $("#poDate").attr("value");
		pseudoSyncRequestElement(
				contextRoot + "/ajax/commonPOrder/getSupplierTaxRate/",
				data,
				function(result) {
					$("#supplierTaxRate").attr("value",result);
				},
				null
		);
	}
}

/*******************************************************************************
 * 商品情報検索・設定
 ******************************************************************************/
//商品コード変更
 function changeProductCode(event) {
 	ProductCodeChange(event.data.index);
}
//商品コード変更時
function ProductCodeChange(id){
	if($("#productCode_" + id).attr("value")==""){
		InitProductInfos(id);
		//しかし、単価->金額の計算は行う
		//指定行全計算(レート換算なし)
		fullCalcLineWithoutRate(id);
		CalcFromDolUnitPrice(id); 
	}else{
	var data = new Object();
	data["tempProductCode"] = $("#productCode_" + id).attr("value");
	asyncRequest(
			contextRoot + "/ajax/commonPOrder/getProductInfosByPost/",
			data,
			function(data) {
				if(data==""){
					var ProductCodeLabel = '<bean:message key="labels.productCode" />';
					alert('<bean:message key="errors.notExist" arg0="'+ProductCodeLabel+'" />');
					InitProductInfos(id);
				}else{
					var value = eval("(" + data + ")");
					SetProductInfosToFroms(id,value);
					//レートによる単価の再計算は商品情報読込み時は行わない仕様とする。（09/12/28確認）
					//明示的に外貨単価が変更された場合は再計算される。
				}
				//しかし、単価->金額の計算は行う
				//指定行全計算(レート換算なし)
				fullCalcLineWithoutRate(id);
				CalcFromDolUnitPrice(id);
			},
			null
	);
	}
}

//商品検索ダイアログ
function searchProductCode(event){
	ProductCodeSearch(event.data.index);
}

function ProductCodeSearch(id){
	openSearchProductDialog( 'product'+id ,
		function(openID,data){
			$("#productCode_" + id).attr("value",data.productCode);
			var param = new Object();
			param["tempProductCode"] = data.productCode;
			asyncRequest(
					contextRoot + "/ajax/commonPOrder/getProductInfosByPost/",
					param,
					function(data) {
						if(data==""){
							var ProductCodeLabel = '<bean:message key="labels.productCode" />';
							alert('<bean:message key="errors.notExist" arg0="'+ProductCodeLabel+'" />');
							InitProductInfos(id);
						}else{
							var value = eval("(" + data + ")");
							SetProductInfosToFroms(id,value);
							//レートによる単価の再計算は商品情報読込み時は行わない仕様とする。（09/12/28確認）
							//明示的に外貨単価が変更された場合は再計算される。
						}
						//しかし、単価->金額の計算は行う
						//指定行全計算(レート換算なし)
						fullCalcLineWithoutRate(id);
						CalcFromDolUnitPrice(id);
					},
					null
			);
		}
	);
	// ダイアログのフィールドに値をセットしてフォーカス
	$("#product" + id + "_productCode").val($("#productCode_" + id).val());
	$("#product" + id + "_productCode").focus();
}

//商品情報設定(初期化)
function InitProductInfos(id){
	$("#productIsExist_" + id).attr("value",CODE_NOEXIST);
	$("#supplierPcode_" + id).attr("value","");
	$("#productSupplierCode_" + id).attr("value","");
	$("#rackCodeDiv_" + id).text("");
	$("#rackCode_" + id).attr("value","");
	$("#productAbstract_" + id).attr("value","");
	$("#productRemarks_" + id).attr("value","");
	$("#unitPrice_" + id).attr("value","");
	$("#dolUnitPrice_" + id).attr("value","");
	$("#poLot_" + id).attr("value","");
	$("#maxPoNum_" + id).attr("value","");
	$("#maxStockNum_" + id).attr("value","");
	$("#holdingStockNum_" + id).attr("value","");
}

//商品情報設定(確定した情報のセット以外には使わないで
function SetProductInfosToFroms(id,value){
	$("#productIsExist_" + id).attr("value",CODE_EXIST);
	$("#supplierPcode_" + id).attr("value",value.supplierPcode);
	$("#productSupplierCode_" + id).attr("value",value.supplierCode);
	$("#productCode_" + id).attr("value",value.productCode);
	$("#productAbstract_" + id).attr("value",value.productName);
	$("#rackCodeDiv_" + id).text(value.rackCode);
	$("#rackCode_" + id).attr("value",value.rackCode);
	$("#productRemarks_" + id).text(value.remarks);
	$("#unitPrice_" + id).attr("value",value.supplierPriceYen);
	_after_load($("#unitPrice_" + id));
	$("#dolUnitPrice_" + id).attr("value",value.supplierPriceDol);
	_after_load($("#dolUnitPrice_" + id));
	$("#poLot_" + id).attr("value",value.poLot);
	_after_load($("#poLot_" + id));
	$("#maxPoNum_" + id).attr("value",value.maxPoNum);
	$("#maxStockNum_" + id).attr("value",value.maxStockNum);
	$("#holdingStockNum_" + id).attr("value", value.holdingStockQuantity);
	$("#productRestQuantity_" + id).attr("value", _Number(value.porderRestQuantity) + _Number(value.entrustRestQuantity) );
	if($("#productIsExist_" + id).attr("value") == CODE_EXIST){
		//仕入先コードが一致しない場合
		if($("#productSupplierCode_" + id).attr("value") != $("#supplierCode").attr("value")){
			alert("<bean:message key='infos.mismatchSupplierProduct'/>");
		}
		//商品が廃番の場合
		if(value.discarded == "1"){
			alert("<bean:message key='warns.product.discarded'/>");
		}
	}

}

/*******************************************************************************
 * 値変更⇒計算連携 (発注日、レート、税率、数量、円単価・金額、外貨単価・金額) + 伝票読込時
 ******************************************************************************/
//伝票読込時
function sumPricesOnLoad(){
	//本体金額計算
	sumPrices();

	var l_priceTotal = oBDCS($("#priceTotal").val()).setSettingsFromObj($("#priceTotal"));
	//本体金額が有効なら
	if( l_priceTotal.isNum() ){
		//DBにある伝票合計情報は再計算はしない
		$("#DISPctaxTotal").valueBDC($("#ctaxTotal").val());
		$("#DISPpriceTotal").valueBDC($("#priceTotal").val());
		$("#DISPfePriceTotal").valueBDC($("#fePriceTotal").val());
	}else{
		//無いなら計算します
		//伝票合計消費税計算 → 伝票合計金額計算
		calcTaxAndTotalPrice();
		//外貨伝票合計
		calcfePriceTotal();
		//伝票合計消費税と矛盾がないように明細行消費税も計算
		for (var i = 0; i < $("#tbodyLine").get(0).children.length; i++){
			id = line2id(i);
			calcLineTax(id);
		}
	}
}

//発注日変更
 function ChangePODate(){
 	pseudoSyncAjaxFunctionList.length = 0;
 	//レートを取得
 	pseudoSyncAjaxFunctionList.push(GetSupplierRate);
 	//税率取得
 	pseudoSyncAjaxFunctionList.push(GetSupplierTaxRate);
 	//レート・税率変更に伴う再計算
 	pseudoSyncAjaxFunctionList.push(ChangeSupplierRateAndTaxRate);
 	pseudoSyncRequest();
 }

//レート・税率変更時
 function ChangeSupplierRateAndTaxRate(){
	//全行計算
	fullCalc();
 }

//ダイアログによる再フォーカス回避のため
var cancel_quantity_refocus = false;

//数量欄にフォーカスイン
function quantity_focus(evt){
	//キャンセル用に変更前の値を取っておく
	if(!cancel_quantity_refocus){
		$("#backup_" + $(evt.target).attr("id")).val(oBDCS($(evt.target).val()).value());
	}
}
//数量欄からフォーカスアウト
function quantity_blur(evt){
	cancel_quantity_refocus = true;
	//行番号取得
	var re4match = new RegExp("^quantity_(\\d{1,2})");
	targetRowNum = $(evt.target).attr("id").replace(re4match,"$1");
	//チェンジイベントを引き起こすか？
	if($("#backup_quantity_"+targetRowNum).val() != oBDCS($(evt.target).val()).value()){
		//チェンジイベントを引き起こす
		if(!quantityChange(targetRowNum)){
			//ダイアログでキャンセルが押された場合
			$("#quantity_"+targetRowNum).valueBDC($("#backup_quantity_"+targetRowNum).val());
			$(evt.target).focus();
			$(evt.target).select();
		}
	}
	checkNowPurchasing(targetRowNum);
	cancel_quantity_refocus = false;
}

function checkNowPurchasing(id){
	// 修正前数量
	var beforeNum = _Number($("#backup_quantity_"+id).val());
	// 修正後数量
	var afterNum = _Number($("#quantity_"+id).val());
	// 残数量
	var restNum = _Number($("#restQuantity_"+id).val());

	// 数量が変わっていなければ何もしない
	if( beforeNum == afterNum ){
		return;
	}
	// 該当明細行の残数調整
	restNum = restNum - ( beforeNum - afterNum );
	$("#restQuantity_"+id).val( restNum );
}

//数量変更
function quantityChange(id){

	//数量適正チェック
	if (_isNum($("#quantity_"+id).attr("value"))){
		var checkString = "";
		var separatorString = "<bean:message key='words.conjunction.and'/>";
		// 仕入済数量未満に設定した場合のチェック
		// チェックするのは分納の時のみ
		if( $("#lineStatus_"+id).val() == <%= Constants.STATUS_PORDER_LINE.NOWPURCHASING %> ){
			if(_isNum($("#restQuantity_"+id).attr("value"))){
				// 元の数量
				var old = _Number($("#backup_quantity_"+id).val());
				// 仕入済数
				var exitNum = old - _Number($("#restQuantity_"+id).val());
				// 新数量　＜　仕入済数はエラー
				if( _Number($("#quantity_"+id).attr("value")) < exitNum ){
					alert('<bean:message key="errors.poQuantity.under"/>');
					return false;
				}
			}
		}
		//発注ロット超過
		if(_isNum($("#poLot_"+id).attr("value"))){
			if( _Number($("#poLot_"+id).attr("value"))
					> _Number($("#quantity_"+id).attr("value"))){
				checkString = "<bean:message key='labels.poLot'/>";
				if(!confirm('<bean:message key="warns.quantity.under" arg0="'+checkString+'"/>')){
					return false;
				}
				checkString = "";
			}
		}
		//発注限度数超過
		if(_isNum($("#maxPoNum_"+id).attr("value"))){
			if( _Number($("#maxPoNum_"+id).attr("value"))
					< _Number($("#quantity_"+id).attr("value"))){
				checkString = checkString +
				(checkString!=""?separatorString:"") +
					"<bean:message key='labels.maxPoNum'/>";
			}
		}
		//在庫限度数超過
		if(_isNum($("#maxStockNum_"+id).attr("value"))){
			if( _Number($("#maxStockNum_"+id).attr("value"))
					< (_Number($("#quantity_"+id).attr("value")) + _Number($("#holdingStockNum_"+id).attr("value")))){
				checkString = checkString +
				(checkString!=""?separatorString:"") +
					"<bean:message key='labels.maxStockNum'/>";
			}
		}
		if(checkString!=""){
			if(!confirm('<bean:message key="warns.quantity.over" arg0="'+checkString+'"/>')){
				return false;
			}
		}
	}

	//指定行全計算(レート換算なし)
	fullCalcLineWithoutRate(id);
	return true;
}

//円単価変更
function changeUnitPrice(event){
	unitPriceChange(event.data.index);
}
function unitPriceChange(id){
	//指定行円単価より後ろ計算
	CalcFromUnitPrice(id);
}

//円金額変更
function changePrice(event){
	priceChange(event.data.index);
}
function priceChange(id){
	//指定行円金額より後ろ計算
	CalcFromPrice(id);
}

//外貨単価変更
function changeDolUnitPrice(event){
	dolUnitPriceChange(event.data.index);
}
function dolUnitPriceChange(id){
	//指定行外貨単価より後ろ計算
	CalcFromDolUnitPrice(id);
}

//外貨金額変更
function changeDolPrice(event){
	dolPriceChange(event.data.index);
}
function dolPriceChange(id){
	//指定行外貨金額より後ろ計算
	CalcFromDolPrice(id);
}

/*******************************************************************************
* 計算部分(連鎖)
******************************************************************************/
//全計算
 function fullCalc(){
	for (var RowNum = 0; RowNum < $("#tbodyLine").get(0).children.length ; RowNum++){
		id = line2id(RowNum);
		if(IsValid(id)){
			//外貨単価⇒円単価
			dolUnitPrice2unitPrice(id);
			//円単価⇒円金額
			unitPrice2price(id);
			//円金額⇒明細行消費税
			calcLineTax(id);
			//外貨単価⇒外貨金額
			dolUnitPrice2dolPrice(id);
		}
	}
	//本体金額計算
	sumPrices();
	//伝票合計消費税計算 → 伝票合計金額計算
	calcTaxAndTotalPrice();
	//外貨伝票合計
	calcfePriceTotal();
}

//指定行全計算(レート換算なし)
 function fullCalcLineWithoutRate(id){
	//指定行外貨単価より後ろ計算(レート換算無し)
	CalcFromDolUnitPriceWithoutRate(id);
	//指定行円単価より後ろ計算
	CalcFromUnitPrice(id);
 }

//指定行外貨単価より後ろ計算
 function CalcFromDolUnitPrice(id){
	//外貨単価⇒円単価
	dolUnitPrice2unitPrice(id);
	//指定行外貨単価より後ろ計算(レート換算無し)
	CalcFromDolUnitPriceWithoutRate(id);
	//指定行円単価より後ろ計算
	CalcFromUnitPrice(id);
 }

//指定行外貨単価より後ろ計算(レート換算無し)
 function CalcFromDolUnitPriceWithoutRate(id){
	//外貨単価⇒外貨金額
	dolUnitPrice2dolPrice(id);
	//外貨伝票合計
	calcfePriceTotal();
 }

//指定行外貨金額より後ろ計算
 function CalcFromDolPrice(id){
	//外貨伝票合計
	calcfePriceTotal();
 }

//指定行円単価より後ろ計算
 function CalcFromUnitPrice(id){
	//円単価⇒円金額
	unitPrice2price(id);
	//円金額⇒明細行消費税
	calcLineTax(id);
	//本体金額計算
	sumPrices();
	//伝票合計消費税計算 → 伝票合計金額計算
	calcTaxAndTotalPrice();
 }

//指定行円金額より後ろ計算
 function CalcFromPrice(id){
	//円金額⇒明細行消費税
	calcLineTax(id);
	//本体金額計算
	sumPrices();
	//伝票合計消費税計算 → 伝票合計金額計算
	calcTaxAndTotalPrice();
 }

/*******************************************************************************
 * 計算部分
 ******************************************************************************/
 //外貨単価⇒円単価
 function dolUnitPrice2unitPrice(id){
 	var l_supplierRate = oBDCS($("#supplierRate").val());
 	var l_dolUnitPrice = oBDCS($("#dolUnitPrice_"+id).val()).setSettingsFromObj($("#dolUnitPrice_"+id));
 	//レートと外貨単価が有効であること
 	if ( l_supplierRate.isNum() && l_dolUnitPrice.isNum()){
 		var dolUnitPrice = l_dolUnitPrice.BDValue();
 		var supplierRate = l_supplierRate.BDValue();
 		$("#unitPrice_"+id).valueBDC(dolUnitPrice.multiply(supplierRate).toString());
 	}
 }

 //外貨単価⇒外貨金額
 function dolUnitPrice2dolPrice(id){
 	var l_quantity     = oBDCS($("#quantity_"+id).val()).setSettingsFromObj($("#quantity_"+id));
 	var l_dolUnitPrice = oBDCS($("#dolUnitPrice_"+id).val()).setSettingsFromObj($("#dolUnitPrice_"+id));
 	//数量と外貨単価が有効であること
 	if ( l_quantity.isNum() && l_dolUnitPrice.isNum()){
 		var dolUnitPrice = l_dolUnitPrice.BDValue();
 		var quantity     = l_quantity.BDValue();
 		$("#dolPrice_"+id).valueBDC(dolUnitPrice.multiply(quantity).toString());
 	}
 }

 //円単価⇒円金額
 function unitPrice2price(id){
 	var l_quantity  = oBDCS($("#quantity_"+id).val()).setSettingsFromObj($("#quantity_"+id));
 	var l_unitPrice = oBDCS($("#unitPrice_"+id).val()).setSettingsFromObj($("#unitPrice_"+id));
 	//数量と円単価が有効であること
 	if ( l_quantity.isNum() && l_unitPrice.isNum()){
 		var unitPrice = l_unitPrice.BDValue();
 		var quantity  = l_quantity.BDValue();
 		$("#price_"+id).valueBDC(unitPrice.multiply(quantity).toString());
 		calcLineTax(id);
 	}
 }

 //円金額⇒明細行消費税
 function calcLineTax(id){
 	//初期化
 	$("#ctaxPrice_"+id).val("");

 	var l_price = oBDCS($("#price_"+id).val());
 	var l_supplierTaxRate = oBDCS($("#supplierTaxRate").val());
 	var l_supplierRate = oBDCS($("#supplierRate").val());

 	//レートが無効で、税率、金額が有効であること。税転嫁が有効範囲内であるとこ
	if( ($("#rateId").val() == "") && (l_supplierTaxRate.isNum()) && (l_price.isNum()) &&
			( ($("#taxShiftCategory").val() == taxShiftCategorySlipTotal) ||
			  ($("#taxShiftCategory").val() == taxShiftCategoryCloseTheBooks) )
				){
 		var TaxRate = l_supplierTaxRate.BDValue();
 		var Price = l_price.BDValue();
 		var Tax = Price.multiply(TaxRate).divide(new BigDecimal("100.0")).toString();
 		$("#ctaxPrice_"+id).valueBDC(Tax);
 	}
 }

//本体金額計算
function sumPrices(){
	var purePriceTotal = new BigDecimal("0");
	var validValueCount = 0;
	var lineSize = $("#tbodyLine").get(0).children.length;
	for(i=0; i<lineSize; i++) {
		id = line2id(i);

		var l_price = oBDCS($("#price_"+id).val()).setSettingsFromObj($("#price_"+id));
		//行が有効行かどうかのチェック(商品コード)
		if(IsValid(id)){
			//金額が有効であること
			if(l_price.isNum()){
				purePriceTotal = purePriceTotal.add(l_price.BDValue());
				validValueCount++;
			}
		}
	}
	$("#DISPpurePriceTotal").valueBDC((validValueCount>0 ? purePriceTotal.toString() : ""));
}

//伝票合計消費税計算 → 伝票合計金額計算
function calcTaxAndTotalPrice(){
	//初期化
	$("#DISPctaxTotal").text("");
	$("#ctaxTotal").val("");
	$("#DISPpriceTotal").text("");
	$("#priceTotal").val("");

	var l_purePriceTotal = oBDCS($("#DISPpurePriceTotal").text()).setSettingsFromObj($("#DISPpurePriceTotal"));
	//本体金額が有効であること
	if( l_purePriceTotal.isNum() ){
		var purePriceTotal = l_purePriceTotal.BDValue();
		var Tax = "";
		var l_supplierTaxRate = oBDCS($("#supplierTaxRate").val());
		//レートIDが無効で、税率が有効であること、税転嫁が指定範囲内であること
		if( ($("#rateId").val() == "") && (l_supplierTaxRate.isNum()) &&
			( ($("#taxShiftCategory").val() == taxShiftCategorySlipTotal) ||
			  ($("#taxShiftCategory").val() == taxShiftCategoryCloseTheBooks) )
				){
			var TaxRate = l_supplierTaxRate.BDValue();
			var Tax = purePriceTotal.multiply(TaxRate).divide(new BigDecimal("100.0")).toString();
			$("#DISPctaxTotal").valueBDC(Tax);
			$("#ctaxTotal").valueBDC(Tax);
		}
		//伝票合計計算
		l_ctaxTotal = oBDCS($("#ctaxTotal").val()).setSettingsFromObj($("#ctaxTotal"));
		var TotalPrice = ((l_ctaxTotal.isNum()) ? purePriceTotal.add(l_ctaxTotal.BDValue()) : purePriceTotal).toString();
		$("#DISPpriceTotal").valueBDC(TotalPrice);
		$("#priceTotal").valueBDC(TotalPrice);
	}
}

//外貨伝票合計
function calcfePriceTotal(){
	//初期化
	$("#DISPfePriceTotal").text("");
	$("#fePriceTotal").val("");

	//レートIDが有効であること
	var l_rateId = oBDCS($("#rateId").val());
	if(l_rateId.isNum()){
		//外貨金額合計
		var dolPriceTotal = new BigDecimal("0");
		var validValueCount = 0;
		for (var i = 0; i < $("#tbodyLine").get(0).children.length ; i++){
			id = line2id(i);
			var l_dolPrice = oBDCS($("#dolPrice_"+id).val()).setSettingsFromObj($("#dolPrice_"+id));
			if(IsValid(id)){
				if(l_dolPrice.isNum()){
					dolPriceTotal = dolPriceTotal.add(l_dolPrice.BDValue());
					validValueCount++;
				}
			}
		}
		$("#DISPfePriceTotal").valueBDC((validValueCount>0 ? dolPriceTotal.toString() : ""));
		$("#fePriceTotal").valueBDC((validValueCount>0 ? dolPriceTotal.toString() : ""));
	}
}

/*******************************************************************************
 * 端数処理用クラス操作
 ******************************************************************************/
//端数処理の規定値
 var defTaxPriceDecAlignment = parseInt('${f:h(defTaxPriceDecAlignment)}');
 var defTaxFractCategory = parseInt('${f:h(defTaxFractCategory)}');

 var defPriceFractCategory = parseInt('${f:h(defPriceFractCategory)}');
 var defUnitPriceDecAlignment = parseInt('${f:h(defUnitPriceDecAlignment)}');
 var defDolUnitPriceDecAlignment = parseInt('${f:h(defDolUnitPriceDecAlignment)}');
 var defNumDecAlignment = parseInt('${f:h(defNumDecAlignment)}');
 var defProductFractCategory = parseInt('${f:h(defProductFractCategory)}');

//外貨通貨記号のリストを取得
 <c:forEach var="cUnitSign" items="${cUnitSignList}" varStatus="s">
 CurrencyUnitClassNameHashList['org_cunit_${s.index}'] = "${cUnitSign}";
 </c:forEach>

//読込み時の適用
function BDCsettingOnLoad(){
	//デフォルトの金額・税端数処理スタイルを適用
	defaultBDCsetting();
	//外貨通貨単位を適用
	$("input:visible.BDCdol").attBDC();

	//数量の端数処理スタイルを適用
	defaultBDCsettingForQuantity();
}

//フォームに端数処理、通貨単位設定（初期値）
 function defaultBDCsetting(){
 	defaultBDCsettingForPrice();
 	defaultBDCsettingForQuantity();
 }
 function defaultBDCsettingForPrice(){
	//どれかひとつが未設定であれば全てが未設定と見てよい(セットされる場合は伝票編集、伝票複写のみ)
	if($("#taxFractCategory").attr("value")==""){
 		$("#taxFractCategory").attr("value",defTaxFractCategory);
 		$("#priceFractCategory").attr("value",defPriceFractCategory);
	}
 	$("#taxPriceDecAlignment").attr("value",defTaxPriceDecAlignment);
 	$("#unitPriceDecAlignment").attr("value",defUnitPriceDecAlignment);
 	$("#dolUnitPriceDecAlignment").attr("value",defDolUnitPriceDecAlignment);
 	CurrencyUnitClassNameHashList['dollar_value'] = "${defaultCUnit}";
	$("#defaultCUnit").val(CurrencyUnitClassNameHashList['dollar_value']);
 	applyBDCsettingForPrice();
 }
 function defaultBDCsettingForQuantity(){
 	//商品毎の数量端数処理は使用しない
 	//伝票に登録しないのでフォームの必要性無し
 	applyBDCsettingForQuantity();
 }

//フォームに端数処理、通貨単位設定
function applyBDCsetting(){
	applyBDCsettingForPrice();
	applyBDCsettingForQuantity();
}
function applyBDCsettingForPrice(){
	//円単価に対しての適用
	$(".BDCyen").setBDCStyle( $("#priceFractCategory").val() ,$("#unitPriceDecAlignment").val() ).attBDC();
	//外貨単価に対しての適用
	$(".BDCdol").setBDCStyle( $("#priceFractCategory").val() ,$("#dolUnitPriceDecAlignment").val() ).attBDC();
	//税に対しての適用
	$(".BDCtax").setBDCStyle( $("#taxFractCategory ").val() ,$("#taxPriceDecAlignment").val() ).attBDC();
}
function applyBDCsettingForQuantity(){
	//数量に対して端数処理の適用
	$(".BDCqua").setBDCStyle( defProductFractCategory ,defNumDecAlignment ).attBDC();
}

/*******************************************************************************
 * 明細行操作
 ******************************************************************************/


//エンターキーによるフォーカス移動を特定の行にバインドする
function bindEnterToLine(id){
	var targetnew = $("#row_"+id+" :input:visible[tabindex>0]" +
			"[type!='hidden'][type!='file'][type!='textarea']" +
			"[type!='reset'][type!='submit'][type!='button'][type!='image']");
	if (targetnew.size() > 0) {
		targetnew.bind('keypress', 'return', move_focus_to_next_tabindex );
	}
}

//アンバインドする
function unbindEnterToLine(id){
	var targetnew = $("#row_"+id+" :input:visible[tabindex>0]" +
			"[type!='hidden'][type!='file'][type!='textarea']" +
			"[type!='reset'][type!='submit'][type!='button'][type!='image']");
	if (targetnew.size() > 0) {
		targetnew.unbind('keypress', move_focus_to_next_tabindex );
	}
}

//明細行情報フォームIDリスト（suffix：_index）
 var LineInfosIdList = new Array(
 		"poLineId",
 		"lineStatus",
 		"dispStatus",			//DB対応無し
 		//"poLineNo",			//常に連番で発番
 		"productCode",
 		"productIsExist",		//DB対応無し
 		"productSupplierCode",	//外部
 		"supplierPcode",
 		"productAbstract",
 		"rackCode",
 		"productRemarks",
 		"quantity",
 		//"tempUnitPriceCategory",	//未使用
 		//"taxCategory",			//未使用
 		//"supplierCmCategory",		//未使用
 		"poLot",				//外部
 		"maxPoNum",				//外部
 		"maxStockNum",
 		"unitPrice",
 		"price",
 		"ctaxPrice",
 		//"ctaxRate",		//伝票から複写
 		"dolUnitPrice",
 		"dolPrice",
 		//"rate",			//伝票から複写
 		"lineDeliveryDate",
 		"lineRemarks",
 		"restQuantity",
 		"productRestQuantity"
 );

//内部：行情報複写
function CopyLineFromTo(fromId,toId){
	for(var i in LineInfosIdList){
		$("#" + LineInfosIdList[i] + "_" + toId).tagValue(
			$("#" + LineInfosIdList[i] + "_" + fromId).tagValue()
		);
	}
}

//内部：行情報消去
function ClearLine(targetId){
	for(var i in LineInfosIdList){
		$("#" + LineInfosIdList[i] + "_" + targetId).tagValue("");
	}
	$("#productIsExist_" + targetId).attr("value",CODE_NOEXIST);
	changeLineStatusLineView(targetId);
}

//内部：行の空欄チェック
function IsNullLine(id){
	var tempStr;
	for(var i in LineInfosIdList){
		tempStr = "";
		tempStr = $("#" + LineInfosIdList[i] + "_" + id).tagValue();
		if(LineInfosIdList[i] == "productIsExist"){
			if(tempStr == CODE_EXIST){return false;}
		}else{
			if(tempStr != ""){return false;}
		}
	}
	return true;
}

//内部：行の表示状態チェック
function IsActive(id){
	return ($("#row_" + id).css("display") != "none");
}

//内部：行の有効行チェック（有効商品コード）
function IsValid(id){
	return ($("#productCode_" + id).attr("value") != "");
}

//1行目の行削除ボタンの有効無効制御
function delAndCopyButtonDisabledControl(){
	var tBodyLine = $("#tbodyLine");
	trId = tBodyLine.children(":first").attr("id");
	id = trId.replace("row_", "");
	lineSize = tBodyLine.children().size();
	// 残り１行の場合、削除ボタンの不活性化
	if(lineSize == 1) {
		if( $("#lineStatus_"+id).val() != <%= Constants.STATUS_PORDER_LINE.ORDERED %> ){
			$("#delButton_"+id).attr("disabled",true);
		}else{
			$("#delButton_"+id).attr("disabled",true);
		}
	}else{
		if( $("#lineStatus_"+id).val() != <%= Constants.STATUS_PORDER_LINE.ORDERED %> ){
			$("#delButton_"+id).attr("disabled",true);
		}else{
			$("#delButton_"+id).attr("disabled",false);
		}
	}
	$("#copyButton_"+id).attr("disabled",true);
}

//行削除
function clickDelLine(event){
	DelLine(event.data.index);
}
function DelLine(id){
<c:if test="${!lockMode}">
	if(!confirm("<bean:message key='confirm.line.delete'/>")){return false;}

	var tBodyLine = $("#tbodyLine");
	var lineSize = $(tbodyLine).get(0).children.length;
	if(lineSize <= 1) return false;
	// 見積明細がある場合はHIDDENに追加する

	var deletePoLineId = $("#poLineId_"+id).val();

	if(deletePoLineId != null && deletePoLineId.length > 0){

		var ids = $("#deleteLineIds").val();
		if(ids.length > 0){
			ids += ",";
		}
		$("#deleteLineIds").val(ids + deletePoLineId);
	}

	if(!IsNullLine(id)) {
		// 変更フラグＯＮ
		changeFlag = true;
	}
	// 行を削除する
	var lineNo = parseInt($("#poLineNo_"+id).val()) -1;

	$("#tbodyLine").get(0).deleteRow(lineNo);
	// 行番号を調整する
	lineSize = $(tBodyLine).children().size();
	for(i=lineNo; i<lineSize; i++) {
		id = line2id(i);
		// 行番号を振りなおす
		$("#poLineNo_"+id).val(i+1);
		$("#lineNo_"+id).html(i+1);
		// 先頭行の場合、前行複写ボタンの不活性化
		if(i == 0) {
			$("#copyButton_"+id).attr("disabled","true");
		}
	}
	// 残り１行の場合、削除ボタンの不活性化
	if(lineSize == 1) {
		trId = $(tBodyLine).children(":first").attr("id");
		id = trId.replace("row_", "");
		$("#delButton_"+id).attr("disabled","true");
	}

	//伝票合計計算
	sumPrices();
	calcTaxAndTotalPrice();
	calcfePriceTotal();

	return true;
</c:if>
}

//前行複写
function clickCopyLine(event){
	CopyLine(event.data.index);
}
function CopyLine(id){
<c:if test="${!lockMode}">
	if(!IsNullLine(id)){
		if(!confirm("<bean:message key='confirm.line.copy'/>")){return false;}
	}
	prevId = $("#tbodyLine").children().get($("#poLineNo_" + id).val() - 2 ).id;
	prevId = prevId.replace("row_", "");
	CopyLineFromTo(prevId,id);

	//複写時に不要な情報を削除
	$("#poLineId_" + id).tagValue("");
	$("#lineStatus_" + id).tagValue("");
	$("#dispStatus_" + id).tagValue("");
	$("#restQuantity_" + id).tagValue("");

	//伝票合計計算
	sumPrices();
	calcTaxAndTotalPrice();
	calcfePriceTotal();

	return true;
</c:if>
}

//行追加
function AddLine(){
<c:if test="${!lockMode}">
	if(maxIndex <= MAX_LINE_ROW_COUNT){
		var elemTr, elemTd, elemWork;
		var lineSize, tabIdx;
		lineSize = $("#tbodyLine").get(0).children.length;
		// ベースオブジェクトからクローンを生成
		elemTr = trCloneBase.clone(true);
		elemTr.find("select").each(
			function() {
				this.selectedIndex = 0;
			}
		);
		// 明細行のIndex管理
		var endLine = $("#tbodyLine").children("[id^='row_']:last");
		var match = endLine.attr("id").match(/^row_([0-9]+)$/);
		if( match ) {
			maxIndex = match[1];
		}
		maxIndex++;
		// タブインデックスの計算
		tabDelta = maxIndex * ${f:h(lineElementCount)} - 1;

		// タブインデックスの再設定
		$(elemTr).find("[tabindex]").each(
			function() {
				if( $(this).attr("tabindex") != undefined && $(this).attr("tabindex") >= 1000 ){
					$(this).attr("tabindex", tabDelta + Number($(this).attr("tabindex"))  );
				}
			}
		);
		$(elemTr).attr("id", $(elemTr).attr("id").replace("_0","_" + maxIndex) );
		$(elemTr).find("[name]").each(
				function() {
					$(this).attr("name", $(this).attr("name").replace("[0]","[" + maxIndex + "]") );
				}
			);
		$(elemTr).find("[id]").each(
			function() {
				$(this).attr("id", $(this).attr("id").replace("_0","_" + maxIndex) );
			}
		);
		$(elemTr).find("[id^='copyButton_']").attr("disabled", false);

		// 行番号設定
		$(elemTr).find("[id^='poLineNo_']").val(lineSize+1);
		$(elemTr).find("[id^='lineNo_']").html(lineSize+1);

		// 行を追加
		$("#tbodyLine").children(":last").after(elemTr);
		setLineEvent( maxIndex );

		delAndCopyButtonDisabledControl();
	}else{
		alert('<bean:message key="errors.line.maxrows" />');
	}
</c:if>
}

function setLineEvent( id ){
	$("#productCode_"+id).bind("focus", {index: id}, function(e){ this.curVal=this.value; });
	$("#productCode_"+id).bind("blur", {index: id}, function(e){ if(this.curVal!=this.value){ this.value=this.value.toUpperCase(); changeProductCode(e); } });
	$("#productSrhImg_"+id).bind("click", {index: id}, searchProductCode);
	$("#productInfBtn_"+id).bind("click", {index: id}, clickShowProductInfos);
	$("#productStkBtn_"+id).bind("click", {index: id}, clickShowStockInfos);
	$("#unitPrice_"+id).bind("focus", {index: id}, function(e){ this.curVal=this.value; });
	$("#unitPrice_"+id).bind("blur", {index: id}, function(e){ if(this.curVal!=this.value){ this.value=this.value.toUpperCase(); changeUnitPrice(e); } });
	$("#price_"+id).bind("focus", {index: id}, function(e){ this.curVal=this.value; });
	$("#price_"+id).bind("blur", {index: id}, function(e){ if(this.curVal!=this.value){ this.value=this.value.toUpperCase(); changePrice(e); } });
	$("#dolUnitPrice_"+id).bind("focus", {index: id}, function(e){ this.curVal=this.value; });
	$("#dolUnitPrice_"+id).bind("blur", {index: id}, function(e){ if(this.curVal!=this.value){ this.value=this.value.toUpperCase(); changeDolUnitPrice(e); } });
	$("#dolPrice_"+id).bind("focus", {index: id}, function(e){ this.curVal=this.value; });
	$("#dolPrice_"+id).bind("blur", {index: id}, function(e){ if(this.curVal!=this.value){ this.value=this.value.toUpperCase(); changeDolPrice(e); } });
	$("#delButton_"+id).bind("click", {index: id}, clickDelLine);
	$("#copyButton_"+id).bind("click", {index: id}, clickCopyLine);
	$("#lineDeliveryDate_"+id).addClass("date_input");
	$("#lineDeliveryDate_"+id).datepicker("destroy");
	$("#lineDeliveryDate_"+id).datepicker(datePickcerSetting);

}
/*******************************************************************************
 * ダイアログ
 ******************************************************************************/

 //在庫ダイアログクリック
 function clickShowStockInfos(event) {
	 showStockInfos(event.data.index);
 }
 function showStockInfos(id) {
 	// 在庫ダイアログを開く
 	var productCode = $("#productCode_" + id).attr("value");
 	if(!productCode){
 		return;
 	}

 	openStockInfoDialog('stockInfo', productCode);
 }

//商品情報ダイアログ呼び出し
function clickShowProductInfos(event){
	showProductInfos(event.data.index);
}
function showProductInfos(id){
	var dialogId = "productInfo_" + id;

	if ($("#" + dialogId).size() > 0) {
		// 既に開いていれば開かない
		return false;
	}
	if( ($("#productCode_" + id).attr("value") == "")
			|| ($("#productIsExist_" + id).attr("value") != CODE_EXIST) ){
		alert("<bean:message key='errors.productNotFound'/>");
		return false;
	}else{

		var data = new Object();
		data["dialogId"] = dialogId;
		data["productCode"] = $("#productCode_" + id).attr("value");
		asyncRequest(
				contextRoot + "/ajax/dialog/showProductInfoDialog/showDialog/"+dialogId,
				data,
				function(result) {
					$("#main_function").after(result);

					$("#"+dialogId).dialog({
					//Options
						autoOpen: false,		//.dialog('open');まで開かないよ
						bgiframe: true,			//for IE6
						closeOnEscape: true,	//ESCで閉じる
						draggable: true,		//ドラッグできるよ
						height: 'auto',			//高さ'auto'で自動
						hide: null,				//閉じるときの効果 'slide'
						modal: false,			//モーダル
						position: 'center',		//'center', 'left', 'right', 'top', 'bottom'
						resizable: false,		//サイズ変更
						show: null,				//開くときの効果'slide'
						stack: true,			//フォーカスを得たときに他のダイアログより前に出る
						width: 950,				//幅 300
					//Events
						close: function(event, ui) { $("#"+dialogId).remove(); }
					});

					$("#"+dialogId).dialog('open');

					return false;
				},
				null
		);
	}
}
/*******************************************************************************/
-->
</script>

</head>
<body>

	
	<%@ include file="/WEB-INF/view/common/titlebar.jsp" %>

	
	<jsp:include page="/WEB-INF/view/common/menubar.jsp">
		<jsp:param name="PARENT_MENU_ID" value="0007"/>
		<jsp:param name="MENU_ID" value="0700"/>
	</jsp:include>

<!-- メイン機能  -->
<div id="main_function">

	<!-- タイトル -->
	<span class="title"><bean:message key='titles.poInput'/></span>

	<div class="function_buttons">
		   <button onclick="onF1()" tabindex="2000">F1<br><bean:message key='words.action.initialize'/></button><!--初期化
<c:if test="${!newData}">

<c:if test="${!lockMode}">
		--><button onclick="onF2()" tabindex="2001">F2<br><bean:message key='words.action.delete'/></button><!--削除
		--><button onclick="onF3()" tabindex="2002">F3<br><bean:message key='words.action.renew'/></button><!--更新
</c:if>
<c:if test="${lockMode}">
		--><button disabled="disabled"   tabindex="2001">F2<br><bean:message key='words.action.delete'/></button><!--削除
		--><button disabled="disabled"   tabindex="2002">F3<br><bean:message key='words.action.renew'/></button><!--更新
</c:if>
		--><button onclick="onF4()" tabindex="2003">F4<br><bean:message key='words.name.pdf'/></button><!--PDF
</c:if>
<c:if test="${newData}">
		--><button disabled="disabled"   tabindex="2001">F2<br><bean:message key='words.action.delete'/></button><!--削除
<c:if test="${!lockMode}">
		--><button onclick="onF3()" tabindex="2002">F3<br><bean:message key='words.action.register'/></button><!--登録
</c:if>
<c:if test="${lockMode}">
		--><button disabled="disabled"   tabindex="2002">F3<br><bean:message key='words.action.register'/></button><!--登録
</c:if>
		--><button disabled="disabled"   tabindex="2003">F4<br><bean:message key='words.name.pdf'/></button><!--PDF
</c:if>
		--><button disabled="disabled"   tabindex="2004">F5<br><bean:message key='words.action.none'/></button><!--
		--><button disabled="disabled"   tabindex="2005">F6<br><bean:message key='words.action.none'/></button><!--伝票呼出
		--><button disabled="disabled"   tabindex="2006">F7<br><bean:message key='words.action.none'/></button><!--
		--><button disabled="disabled"   tabindex="2007">F8<br><bean:message key='words.action.none'/></button><!--
		--><button disabled="disabled"   tabindex="2008">F9<br><bean:message key='words.action.none'/></button><!--
		--><button disabled="disabled"   tabindex="2009">F10<br><bean:message key='words.action.none'/></button><!--
		--><button disabled="disabled"   tabindex="2010">F11<br><bean:message key='words.action.none'/></button><!--
		--><button disabled="disabled"   tabindex="2011">F12<br><bean:message key='words.action.none'/></button>
	</div>

	<s:form onsubmit="return false;">

	<div class="function_forms">

	<div id="errors" style="color: red">
		<html:errors/>
	</div>
	<div id="ajax_errors" style="color: red"></div>
	<div id="messages" style="color: blue;">
		<html:messages id="msg" message="true">
			<bean:write name="msg" ignore="true"/><br>
		</html:messages>
	</div>
	<!-- 発注伝票情報  -->
		<span><bean:message key='labels.poSlipInfos'/></span><br>
		<table class="forms" summary="poSlipInfos">
			<colgroup>
				<col span="1" style="width: 10%">
				<col span="1" style="width: 14%">
				<col span="1" style="width: 10%">
				<col span="1" style="width: 14%">
				<col span="1" style="width: 10%">
				<col span="1" style="width: 14%">
				<col span="1" style="width: 10%">
				<col span="1" style="width: 18%">
			</colgroup>
			<tr>
				<th><bean:message key='labels.poSlipId'/></th><!-- 発注番号 -->
				<td><html:text styleId="poSlipId" property="poSlipId" readonly="false" styleClass="" style="width:100px; ime-mode:disabled;" tabindex="100"  onfocus="this.curVal=this.value;" onblur="if((this.curVal == '') || ((this.curVal != '')&&(this.curVal!=this.value))){ findSlip()}"/></td>
				<th><bean:message key='labels.poDate'/><bean:message key='labels.must'/></th><!-- 発注日 -->
				<td><html:text styleId="poDate" property="poDate" styleClass="date_input" maxlength="${f:h(ML_DATE)}" style="width:100px;" tabindex="101" onchange="ChangePODate()"/></td>
				<th><bean:message key='labels.deliveryDate'/><bean:message key='labels.must'/></th><!-- 納期 -->
				<td><html:text styleId="deliveryDate" property="deliveryDate" maxlength="${f:h(ML_DATE)}" styleClass="date_input" style="width:100px;" tabindex="102"/></td>
				<th><bean:message key='labels.userName'/></th><!-- 入力担当者 -->
				<td><html:text styleId="userName" property="userName" readonly="true" styleClass="c_disable" style="width:100px;" tabindex="103"/>
				<html:hidden property="userId"/></td>
				<html:hidden property="menuUpdate"/>
				<html:hidden property="newData"/>
				<html:hidden property="updDatetm"/>
				<html:hidden property="updUser"/>
				<html:hidden property="deleteLineIds"  styleId="deleteLineIds"/>
			</tr>
			<tr>
				<th><bean:message key='labels.memorandum'/></th><!-- 摘要 -->
				<td colspan="5"><html:text styleId="remarks" property="remarks" maxlength="${f:h(ML_REMARK)}" style="width: 550px" tabindex="105"/></td>
				<th><bean:message key='labels.transportCategory'/></th><!-- 運送便区分 -->
				<td>
					<html:select styleId="transportCategory" property="transportCategory" tabindex="106">
						<c:forEach var="bean" items="${transportCategoryList}">
							<html:option value="${bean.value}">${f:h(bean.label)}</html:option>
						</c:forEach>
					</html:select>
				</td>
			</tr>
		</table>
		<html:hidden property="status"/>
		<html:hidden property="printCount"/>
	<!-- 仕入先情報  -->
		<span><bean:message key='labels.supplierInfos'/></span><br>
		<table class="forms" summary="supplierInfos">
			<colgroup>
				<col span="1" style="width: 10%">
				<col span="1" style="width: 20%">
				<col span="1" style="width: 10%">
				<col span="1" style="width: 25%">
				<col span="1" style="width: 10%">
				<col span="1" style="width: 12%">
				<col span="1" style="width: 10%">
				<col span="1" style="width: 13%">
			</colgroup>
			<tr>
				<th><bean:message key='labels.supplierCode'/><bean:message key='labels.must'/></th><!-- 仕入先コード -->
				<td><html:text styleId="supplierCode" styleClass="c_ime_off" property="supplierCode" maxlength="${f:h(ML_SUPPLIERCODE)}" style="width: 100px" tabindex="200"
						onfocus="this.curVal=this.value;" onblur="if(this.curVal!=this.value){ ChangeSupplierCode(); }"/>
					<html:hidden styleId="supplierIsExist" property="supplierIsExist"/>
					<html:image src="${f:url('/images/icon_04_02.gif')}" style="vertical-align: middle; cursor: pointer;" tabindex="201" onclick="supplierSearch()"/></td>
				<th><bean:message key='labels.supplierName'/></th><!-- 仕入先名 -->
				<td><html:text styleId="supplierName" property="supplierName" style="width: 250px" tabindex="202" readonly="true" styleClass="c_disable"/></td>
				<th><bean:message key='labels.supplierKana'/></th><!-- 仕入先名カナ -->
				<td colspan="3"><html:text styleId="supplierKana" property="supplierKana" style="width: 250px" tabindex="203" readonly="true" styleClass="c_disable"/></td>
			</tr>
			<tr>
				<th><bean:message key='labels.zipCode'/></th><!-- 郵便番号 -->
				<td><html:text styleId="supplierZipCode" property="supplierZipCode" tabindex="204" style="width: 70px" readonly="true" styleClass="c_disable"/></td>
				<th><bean:message key='labels.address1'/></th><!-- 住所1 -->
				<td><html:text styleId="supplierAddress1" property="supplierAddress1" tabindex="205" style="width: 250px" readonly="true" styleClass="c_disable"/></td>
				<th><bean:message key='labels.address2'/></th><!-- 住所2 -->
				<td colspan="3"><html:text styleId="supplierAddress2" property="supplierAddress2" tabindex="206" style="width: 250px" readonly="true" styleClass="c_disable"/></td>
			</tr>
			<tr>
				<th><bean:message key='labels.pcName'/></th><!-- 担当者 -->
				<td><html:text styleId="supplierPcName" property="supplierPcName" style="width: 150px" tabindex="207" readonly="true" styleClass="c_disable"/></td>
				<th><bean:message key='labels.pcKana'/></th><!-- 担当者カナ -->
				<td><html:text styleId="supplierPcKana" property="supplierPcKana" style="width: 150px" tabindex="208" readonly="true" styleClass="c_disable"/></td>
				<th><bean:message key='labels.pcPreCategory'/></th><!-- 敬称 -->
				<td>
					<html:select styleId="supplierPcPreCategory" property="supplierPcPreCategory" tabindex="209" styleClass="c_disable">
							<html:option value="-1">&nbsp;</html:option>
						<c:forEach var="bean" items="${preTypeCategoryList}">
							<html:option value="${bean.value}">${f:h(bean.label)}</html:option>
						</c:forEach>
					</html:select>
				</td>
				<th><bean:message key='labels.pcPost'/></th><!-- 役職 -->
				<td><html:text styleId="supplierPcPost" property="supplierPcPost" tabindex="210" style="width: 80px" readonly="true" styleClass="c_disable"/></td>
			</tr>
			<tr>
				<th><bean:message key='labels.tel'/></th><!-- TEL -->
				<td><html:text styleId="supplierTel" property="supplierTel" tabindex="211" style="width: 150px" readonly="true" styleClass="c_disable"/></td>
				<th><bean:message key='labels.email'/></th><!-- E-MAIL -->
				<td colspan="5"><html:text styleId="supplierEmail" property="supplierEmail" tabindex="212" style="width: 400px" readonly="true" styleClass="c_disable"/></td>
			</tr>
			<tr>
				<th><bean:message key='labels.fax'/></th><!-- FAX -->
				<td><html:text styleId="supplierFax" property="supplierFax" tabindex="213" style="width: 150px" readonly="true" styleClass="c_disable"/></td>
				<td colspan="6">
					<html:hidden property="supplierRate" styleId="supplierRate"/>
					<html:hidden property="taxRate" styleId="supplierTaxRate"/>
					<html:hidden property="supplierAbbr" styleId="supplierAbbr"/>
					<html:hidden property="supplierDeptName" styleId="supplierDeptName"/>
					<html:hidden property="supplierPcPre" styleId="supplierPcPre"/>
					<html:hidden property="defaultCUnit" styleId="defaultCUnit"/>
					<html:hidden property="defTaxFractCategory" styleId="defTaxFractCategory"/>
					<html:hidden property="defTaxPriceDecAlignment" styleId="defTaxPriceDecAlignment"/>
					<html:hidden property="defPriceFractCategory" styleId="defPriceFractCategory"/>
					<html:hidden property="defDolUnitPriceDecAlignment" styleId="defDolUnitPriceDecAlignment"/>
					<html:hidden property="defUnitPriceDecAlignment" styleId="defUnitPriceDecAlignment"/>
					<html:hidden property="defProductFractCategory" styleId="defProductFractCategory"/>
					<html:hidden property="defNumDecAlignment" styleId="defNumDecAlignment"/>
				</td>
			</tr>
		</table>
		<html:hidden property="taxFractCategory" styleId="taxFractCategory"/>
		<html:hidden property="taxPriceDecAlignment" styleId="taxPriceDecAlignment"/>

		<html:hidden property="priceFractCategory" styleId="priceFractCategory"/>
		<html:hidden property="unitPriceDecAlignment" styleId="unitPriceDecAlignment"/>
		<html:hidden property="dolUnitPriceDecAlignment" styleId="dolUnitPriceDecAlignment"/>

		<html:hidden property="rateId" styleId="rateId"/>
		<html:hidden property="taxShiftCategory" styleId="taxShiftCategory"/>
	<!-- 支払状況 -->
		<span><bean:message key='labels.paymentStatus'/></span><br>
		<table class="forms" style="width: 910px" summary="paymentStatus">
			<colgroup>
				<col span="1" style="width: 10%">
				<col span="1" style="width: 20%">
				<col span="1" style="width: 10%">
				<col span="1" style="width: 60%">
			</colgroup>
			<tr>
				<th><bean:message key='labels.paymentStatus'/></th><!-- 支払状況 -->
				<td><span id="paymentStatus">${f:h(slipPaymentStatus)}</span>&nbsp;</td>
				<th><bean:message key='labels.paymentDate'/></th><!-- 支払日 -->
				<td><span id="paymentDate">${f:h(slipPaymentDate)}</span>&nbsp;</td>
			</tr>
		</table>
	<!-- 発注伝票明細リスト -->
		<table summary="poLines" class="forms" style="margin-top: 20px; margin-bottom: 0px; border-bottom: 0px;">
			<colgroup>
				<col span="1" style="width:  25px;">
				<col span="1" style="width: 170px;">
				<col span="1" style="">
				<col span="1" style="width:  60px;">
				<col span="1" style="width:  60px;">
				<col span="1" style="width: 110px;">
				<col span="1" style="width: 120px;">
				<col span="1" style="width: 145px;">
				<col span="1" style="width:  80px;">
			</colgroup>
			<thead>
			<tr>
				<th rowspan="2"><bean:message key='labels.lineNo'/></th><!-- No. -->
				<th><bean:message key='labels.productCode'/><bean:message key='labels.must'/></th><!-- 商品コード -->
				<th><bean:message key='labels.rackCode'/></th><!-- 棚番 -->
				<th><bean:message key='labels.poLot'/></th><!-- ロット -->
				<th><bean:message key='labels.deliveryProcessCategory'/></th><!-- 完納区分 -->
				<th><bean:message key='labels.unitPrice'/><span class="yenMust"><bean:message key='labels.must'/></span></th><!-- 円単価  -->
				<th><bean:message key='labels.price'/><span class="yenMust"><bean:message key='labels.must'/></span></th><!-- 金額(円) -->
				<th><bean:message key='labels.remarks'/></th><!-- 備考 -->
				<th rowspan="2">&nbsp;</th>
			</tr>
			<tr>
				<th><bean:message key='labels.purchasePcode'/></th><!-- 仕入先商品コード -->
				<th><bean:message key='labels.productRemarks'/></th><!-- 商品備考 -->
				<th><bean:message key='labels.quantity'/><bean:message key='labels.must'/></th><!-- 数量 -->
				<th><bean:message key='labels.allRestQuantity'/></th><!-- 総発注残 -->
				<th><bean:message key='labels.dolUnitPrice'/><span class="dolMust"><bean:message key='labels.must'/></span></th><!-- 外貨単価 -->
				<th><bean:message key='labels.dolPrice'/><span class="dolMust"><bean:message key='labels.must'/></span></th><!-- 外貨金額 -->
				<th><bean:message key='labels.deliveryDate'/></th><!-- 納期 -->
			</tr>
			</thead>
		<tbody id="tbodyLine">
		<c:forEach var="poLineList" items="${poLineList}" varStatus="s">
		<tr id="row_${f:h(s.index)}">
				<td style="text-align:right;">
					<html:hidden styleId="poLineId_${s.index}" name="poLineList" property="poLineId" indexed="true" /><!-- 行ID -->
					<html:hidden styleId="poLineNo_${s.index}" name="poLineList" property="lineNo" indexed="true" value="${s.count}"/>
					<span id="lineNo_${s.index}" >${f:h(s.count)}</span>
				</td>
				<td>
					<html:text styleId="productCode_${s.index}" styleClass="c_ime_off" name="poLineList" property="productCode" indexed="true" maxlength="${f:h(ML_PRODUCTCODE)}" style="width: 165px" tabindex="${f:h(s.index)*f:h(lineElementCount)+1000}" />
						<html:image styleId="productSrhImg_${s.index}" src="${f:url('/images/icon_04_02.gif')}" style="vertical-align: middle; cursor: pointer;" tabindex="${f:h(s.index)*f:h(lineElementCount)+1002}"/><br>
					<html:text styleId="supplierPcode_${s.index}" styleClass="c_ime_off" name="poLineList" property="supplierPcode" indexed="true" maxlength="${f:h(ML_PRODUCTCODE)}" style="width: 150px" tabindex="${f:h(s.index)*f:h(lineElementCount)+1001}"/>
					<input type="hidden" id="productSupplierCode_${s.index}">
				</td>
				<td style="white-space: normal">
					<div id="rackCodeDiv_${f:h(s.index)}" style="position: static; width:135px; height:50px; white-space: normal;">${f:h(poLineList.rackCode)}</div>
					<html:hidden styleId="rackCode_${f:h(s.index)}" name="poLineList" property="rackCode" indexed="true" />
					<html:textarea styleId="productRemarks_${s.index}" name="poLineList" property="productRemarks"  indexed="true" style="width: 135px; height: 50px;" tabindex="${f:h(s.index)*f:h(lineElementCount)+1003}" readonly="true" styleClass="c_disable"/>
					<html:hidden styleId="productAbstract_${s.index}" name="poLineList" property="productAbstract" indexed="true" />
					<html:hidden styleId="productIsExist_${s.index}" name="poLineList" property="productIsExist" indexed="true" />
				</td>

				<td><html:text styleId="poLot_${f:h(s.index)}" name="poLineList" property="poLot" indexed="true" style="width: 50px;" readonly="true" styleClass="c_disable numeral_commas BDCqua" tabindex="${f:h(s.index)*f:h(lineElementCount)+1004}"/><br>
					<html:hidden styleId="maxPoNum_${f:h(s.index)}" name="poLineList" property="maxPoNum" indexed="true" /><!-- 発注限度数 -->
					<html:hidden styleId="maxStockNum_${f:h(s.index)}" name="poLineList" property="maxStockNum" indexed="true" /><!-- 在庫限度数 -->
					<html:hidden styleId="holdingStockNum_${f:h(s.index)}" name="poLineList" property="holdingStockNum" indexed="true" /><!-- 在庫限度数 -->
					<html:text styleId="quantity_${s.index}" name="poLineList" property="quantity" indexed="true" maxlength="${f:h(ML_S_QUANTITY)}" styleClass="numeral_commas BDCqua" style="width: 50px;" tabindex="${f:h(s.index)*f:h(lineElementCount)+1005}"/><br>
					<input type="hidden" id="backup_quantity_${s.index}" value=""/>
					<button id="productInfBtn_${s.index}" style="width: 50px;" tabindex="${f:h(s.index)*f:h(lineElementCount)+1006}"><bean:message key='words.action.showProductInfos'/></button><!-- (商品)情報 -->
					<button id="productStkBtn_${s.index}" style="width: 50px;" tabindex="${f:h(s.index)*f:h(lineElementCount)+1007}"><bean:message key='words.action.showStockInfos'/></button></td><!-- (商品)在庫 -->
				<td>
					<html:hidden styleId="lineStatus_${s.index}" name="poLineList" property="status" indexed="true" />
					<span id="dispStatus_${s.index}" style="width: 55px; text-align:center;">${f:h(poLineList.dispStatus)}</span>
<!--  					<html:text styleId="restQuantity_${s.index}" name="poLineList" property="restQuantity" indexed="true" style="width: 50px; text-align:right; background-color: #FFFFFF; border-style: none;" readonly="true" styleClass="numeral_commas BDCqua" />  -->
 					<html:hidden styleId="restQuantity_${s.index}" name="poLineList" property="restQuantity" indexed="true" style="width: 50px; text-align:right; background-color: #FFFFFF; border-style: none;" styleClass="numeral_commas BDCqua" />
					<html:text styleId="productRestQuantity_${s.index}" name="poLineList" property="productRestQuantity" indexed="true" style="width: 50px; text-align:right; background-color: #FFFFFF; border-style: none;" readonly="true" styleClass="numeral_commas BDCqua" />
				</td>
				<td colspan="2">
				<html:text styleId="unitPrice_${s.index}" name="poLineList" property="unitPrice" indexed="true" maxlength="${f:h(ML_S_UNITPRICE)}" styleClass="numeral_commas yen_value BDCyen" style="width: 105px;" tabindex="${f:h(s.index)*f:h(lineElementCount)+1009}"/>
				<html:text styleId="price_${s.index}" name="poLineList" property="price" indexed="true" maxlength="${f:h(ML_S_PRICE)}" styleClass="numeral_commas yen_value BDCyen" style="width: 105px;" tabindex="${f:h(s.index)*f:h(lineElementCount)+1011}"/><br>
				<html:hidden styleId="ctaxPrice_${s.index}" styleClass="BDC BDCtax" name="poLineList" property="ctaxPrice" indexed="true" />
				<html:text styleId="dolUnitPrice_${s.index}" name="poLineList" property="dolUnitPrice" indexed="true" maxlength="${f:h(ML_S_UNITPRICE)}" styleClass="numeral_commas dollar_value BDCdol" style="width: 105px;" tabindex="${f:h(s.index)*f:h(lineElementCount)+1010}"/>
				<html:text styleId="dolPrice_${s.index}" name="poLineList" property="dolPrice" indexed="true" styleClass="numeral_commas dollar_value BDCdol" maxlength="${f:h(ML_S_PRICE)}" style="width: 105px;" tabindex="${f:h(s.index)*f:h(lineElementCount)+1012}"/>
				</td>

				<td>
					<html:textarea styleId="lineRemarks_${s.index}" name="poLineList" property="remarks" indexed="true" style="width: 140px; height: 70px;" tabindex="${f:h(s.index)*f:h(lineElementCount)+1013}"/><br><!-- 備考 -->
					<html:text styleId="lineDeliveryDate_${s.index}" name="poLineList" property="deliveryDate" indexed="true" maxlength="${f:h(ML_DATE)}" style="width: 124px;" tabindex="${f:h(s.index)*f:h(lineElementCount)+1014}"/>
				</td>
				<td style="text-align:right;">
<c:if test="${!lockMode}">
					<button id="delButton_${s.index}" style="width: 80px" tabindex="${f:h(s.index)*f:h(lineElementCount)+1015}"><bean:message key='words.action.delLine'/></button><br><!-- (行)削除 -->
</c:if>
<c:if test="${lockMode}">
					<button id="delButton_${s.index}" style="width: 80px" disabled="disabled"><bean:message key='words.action.delLine'/></button><br><!-- (行)削除 -->
</c:if>
<c:if test="${!lockMode}">
		<c:if test="${s.count == 1}">
					<button id="copyButton_${s.index}" style="width: 80px" disabled="disabled"><bean:message key='words.action.copyFromPreviousLine'/></button><!-- 前行複写 -->
		</c:if>
		<c:if test="${s.count >  1}">
					<button id="copyButton_${s.index}" style="width: 80px" tabindex="${f:h(s.index)*f:h(lineElementCount)+1016}" ><bean:message key='words.action.copyFromPreviousLine'/></button><!-- 前行複写 -->
		</c:if>
</c:if>
<c:if test="${lockMode}">
					<button id="copyButton_${s.index}" style="width: 80px" disabled="disabled"><bean:message key='words.action.copyFromPreviousLine'/></button><!-- 前行複写 -->
</c:if>
				</td>
			</tr>
		</c:forEach>
			</tbody>
	    </table>
		<table summary="poLines" class="forms" style="margin-top: 0px; border-top: 1px gray solid;">
			<tfoot>
			<tr id="rowAddLine">
				<td style="text-align: right;" colspan="9">
					<html:hidden styleId="slipLineActive" property="slipLineActive"/>
<c:if test="${!lockMode}">
					<button tabindex="1800" style="width: 80px;" onClick="AddLine()"><bean:message key='words.action.addLine'/></button><!-- 行追加 -->
</c:if>
<c:if test="${lockMode}">
					<button style="width: 80px;" disabled="disabled"><bean:message key='words.action.addLine'/></button><!-- 行追加 -->
</c:if>
				</td>
			</tr>
			</tfoot>
		</table>

	<!-- 伝票金額情報 -->
		<div id="poSlipPriseInfos" class="information" style="margin-top: 20px; height: 40px;">
			<table class="forms" summary="poSlipPriseInfos" style="width: 450px; position: absolute; top: 0px; left: 460px;">
				<colgroup>
					<col span="4" style="width: 25%">
				</colgroup>
				<tr>
					<th><bean:message key='labels.purePriceTotal'/></th><!-- 本体金額(円) -->
					<th><bean:message key='labels.ctaxTotal'/></th><!-- 消費税 -->
					<th><bean:message key='labels.priceTotal'/></th><!-- 伝票合計(円) -->
					<th><bean:message key='labels.fePriceTotal'/></th><!-- 外貨伝票合計 -->
				</tr>
				<tr>
					<td style="text-align: right;" >
						&nbsp;<span id="DISPpurePriceTotal" class="BDCyen yen_value"></span>
					</td>
					<td style="text-align: right;" >
						<span id="DISPctaxTotal" class="BDCtax yen_value"></span>
						<html:hidden styleId="ctaxTotal" styleClass="BDC BDCtax" property="ctaxTotal"/>

					</td>
					<td style="text-align: right;" >
						<span id="DISPpriceTotal" class="BDCyen yen_value"></span>
						<html:hidden styleId="priceTotal" styleClass="BDC BDCyen" property="priceTotal"/>
					</td>
					<td style="text-align: right;" >
						<span id="DISPfePriceTotal" class="BDCdol dollar_value"></span>
						<html:hidden styleId="fePriceTotal" styleClass="BDC BDCdol" property="fePriceTotal"/>
					</td>
				</tr>
			</table>
		</div>
				<div style="text-align: right; width: 910px">
					<c:if test="${!newData}">
						<c:if test="${!lockMode}">
							<button onclick="onF3()" tabindex="1999"><bean:message key='words.action.renew'/></button>
						</c:if>
						<c:if test="${lockMode}">
							<button disabled="disabled"   tabindex="1999"><bean:message key='words.action.renew'/></button>
						</c:if>
					</c:if>
					<c:if test="${newData}">
						<c:if test="${!lockMode}">
							<button onclick="onF3()" tabindex="1999"><bean:message key='words.action.register'/></button>
						</c:if>
						<c:if test="${lockMode}">
							<button disabled="disabled"   tabindex="1999"><bean:message key='words.action.register'/></button>
						</c:if>
					</c:if>
				</div>

	</div>
</s:form>
		<form name="PDFOutputForm" action="${f:url('/porder/makeOutPOrderResultOutput/pdf')}" style="display: none;" method="POST">
		</form>
</body>

</html>

