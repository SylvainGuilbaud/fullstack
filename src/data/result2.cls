Class data.result2 Extends (%Persistent, %JSON.Adaptor, %XML.Adaptor, %Populate)
{

Property key As %Integer(MINVAL = 1) [ Required ];

Property column As data.column [ Required ];

Property value As %String(MAXLEN = "", POPSPEC = "##class(data.result).popValue()") [ Required ];

Property inserted As %TimeStamp [ InitialExpression = {$zdt($h,3)}, Required ];

Index keyColumn On (key, column) [ Data = value, Unique ];

Index columnIndex On column [ Type = bitmap ];

ClassMethod insert(key As %Integer, column As %String, value As %String) As %Status
{
    Set sc = $$$OK

    set result = ..%New()
    set result.key = key
    set col = ##class(data.column).%New()
    set col.name = column
    set result.column = col
    set result.value = value
    
    set sc = result.%Save()
    if sc {
        write !,"new result inserted in ",result.%Id(),!
    } else {
        do $system.OBJ.DisplayError(sc)
    }
    
    Return sc
}

ClassMethod init(nb As %Integer = 1000, reset As %Boolean = 1) As %Status
{
    Set sc = $$$OK
    if reset {
        set sc = ..%KillExtent()
        set nbColumns = ##class(data.column).init()
        kill ^backupdata.resultD,^backupdata.resultI,^backupdata.resultS
    }
    set rs = ##class(%SQL.Statement).%ExecDirect(,"select name from data.column")
    set columnList = ""
    while rs.%Next() {
        set columnList = columnList _ $lb(rs.%Get("name"))
    }
    for i = 1:1:nb {
        set timestamp = $zdt($h-($random(365*10)),3)
        for j = 1:1:$random($ll(columnList))+1 {
            set result = ..%New()
            set result.key = i
            set result.inserted = timestamp
            set result.column = ##class(data.column).%OpenId($lg(columnList,j))
            if result.column.name="Couleur" {
                set result.value = ..popValue()
            }
            elseif result.column.name["Adresse" {
                set result.value = ##class(%PopulateUtils).Street()
            }
            elseif result.column.name["hone" {
                set result.value = ##class(%PopulateUtils).USPhone()
            }
            elseif result.column.name["Email" {
                set result.value = ##class(%PopulateUtils).FirstName()_"."_##class(%PopulateUtils).LastName()_"@"_##class(%PopulateUtils).City()_".com"
            }
            elseif result.column.name["IBAN" {
                set result.value = ##class(%PopulateUtils).Integer(10000000000,90000000000)
            }
            else {
                set result.value = ##class(%PopulateUtils).Syllable()
            }
            
            set sc = result.%Save()
        }
    }
    #; do ..Populate(nb)

    &SQL(select count(*) into :nbResults from data.result2)
    write !,nbResults," inserted in ",..%ClassName(1),!
    Return sc
}

ClassMethod popValue() As %String
{
    set t1=$lb("Rouge","Vert","Bleu","Jaune","Noir","Blanc","Orange","Violet","Parme","Prune","Marron","Gris","Rose","Fuschia","Crème","Cuivre","Fumée","Glycine","Framboise")
    return $li(t1,$$$PRand($ll(t1))+1)
}

ClassMethod popColumn(ByRef list) As %String
{
  
    #; set t1=$lb("Rouge","Vert","Bleu","Jaune","Noir","Blanc","Orange","Violet","Parme","Prune","Marron","Gris","Rose","Fuschia","Crème","Cuivre","Fumée","Glycine","Framboise")
    return $li(list,$$$PRand($ll(list))+1)
}

ClassMethod get(search As %String = "Renault", columnName As %String = "Marque") As %DynamicArray
{
    set key="",json=[]
    SET key=$ORDER(^data.result(""))
    WHILE (key'="") {
        #; WRITE key,!
        if $Get(^data.result(key,columnName)) = search {
            write key,!
            set data={}
            set data.id=key
            set column = ""

            set column = $ORDER(^data.result(key,column),1,target)

            set data.contents={}
            set data.contents.column=(column)
            set data.contents.value=(target)
    
            do json.%Push(data)
             
        }
        // Get next subscript
        SET key = $ORDER(^data.result(key))
    }
    Return json
}

Query data(globalName As %String) As %Query(ROWSPEC = "ID:%String,key2:%String,key3:%String,key4:%String,key5:%String,key6:%String,datavalue:%String") [ SqlProc ]
{
}

ClassMethod dataExecute(ByRef qHandle As %Binary, globalName As %String) As %Status
{
    Set qHandle("node") = globalName
    Quit $$$OK
}

ClassMethod dataFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Boolean) As %Status [ PlaceAfter = dataExecute ]
{
    Set sc = $$$OK
    Set qHandle("node") = $Query(@qHandle("node"), 1, data)
    If qHandle("node") = "" Set Row = "", AtEnd = $$$YES Quit $$$OK
    ; feeds the key x fields based on the subscripts of the global
    For i=1:1:$QLength(qHandle("node")) Set $List(Row, i) = $QSubscript(qHandle("node"), i)
    If i < 6 { ; if we do not have 6 subscripts, we feed the rest with an empty string
    For j = i+1:1:6 Set $List(Row, j) = ""
    }

    Set $List(Row, 7) = data, AtEnd = $$$NO
    Quit sc
}

ClassMethod dataClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = dataExecute ]
{
    Kill qHandle Quit $$$OK
}

Storage Default
{
<Data name="result2DefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>key</Value>
</Value>
<Value name="3">
<Value>column</Value>
</Value>
<Value name="4">
<Value>value</Value>
</Value>
<Value name="5">
<Value>inserted</Value>
</Value>
</Data>
<DataLocation>^data.result2D</DataLocation>
<DefaultData>result2DefaultData</DefaultData>
<IdLocation>^data.result2D</IdLocation>
<IndexLocation>^data.result2I</IndexLocation>
<StreamLocation>^data.result2S</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}