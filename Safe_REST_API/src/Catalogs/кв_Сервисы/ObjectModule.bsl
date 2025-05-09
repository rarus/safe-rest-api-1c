///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022-2025, ООО 1С-Рарус
// Все права защищены. Эта программа и сопроводительные материалы предоставляются
// в соответствии с условиями лицензии Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by-sa/4.0/legalcode
//////////////////////////////////////////////////////////////////////////////////////////////////////

#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

#Область ОбработчикиСобытий

Процедура ОбработкаПроверкиЗаполнения(Отказ, ПроверяемыеРеквизиты)
	
	ПроверитьРеквизитыПриКонтролеКонфликтов(Отказ, ПроверяемыеРеквизиты);
	
	ПроверитьНаличиеСервисаПоКорневомуURL(Отказ);
	
	ПроверитьНаличиеДублейСервисов(Отказ);
	
КонецПроцедуры

Процедура ПриКопировании(ОбъектКопирования)
	
	Наименование = "";	
	
КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

Процедура ПроверитьРеквизитыПриКонтролеКонфликтов(Отказ, ПроверяемыеРеквизиты)
	
	Если КонтрольКонфликтовЗапросов Тогда
		
		ПроверяемыеРеквизиты.Добавить("ПорогРазблокировкиКонфликтов");
		ПроверяемыеРеквизиты.Добавить("ПовторовДоРазблокировкиКонфликтов");
		ПроверяемыеРеквизиты.Добавить("ПериодПроверкиПорогаРазблокировки");
		
	КонецЕсли;
	
КонецПроцедуры

Функция ОбнаруженСервисПоКорневомуURL()
	
	Для каждого Сервис Из Метаданные.HTTPСервисы Цикл
		Если НРег(Сервис.КорневойURL) = НРег(Наименование) Тогда
			Возврат Истина;
		КонецЕсли;
	КонецЦикла;
	
	Возврат Ложь;

КонецФункции

Процедура ПроверитьНаличиеСервисаПоКорневомуURL(Отказ)
	
	Если ОбнаруженСервисПоКорневомуURL() Тогда
		Возврат;
	КонецЕсли;
	
	Шаблон = НСтр("ru = 'HTTP-сервис с корневым URL ""%1"" не обнаружен'");
	ТекстСообщения = СтрШаблон(Шаблон, Наименование);
	кв_ОбщегоНазначенияКлиентСервер.СообщитьПользователю(ТекстСообщения, , "Наименование", "Объект", Отказ);
	
КонецПроцедуры

Процедура ПроверитьНаличиеДублейСервисов(Отказ)
	
	Если ПустаяСтрока(Наименование) Тогда
		Возврат;
	КонецЕсли;
		
	Запрос = Новый Запрос;
	Запрос.УстановитьПараметр("Ссылка", Ссылка);
	Запрос.УстановитьПараметр("Наименование", Наименование);
	Запрос.Текст = 
	"ВЫБРАТЬ ПЕРВЫЕ 1
	|	кв_Сервисы.Наименование КАК Наименование,
	|	кв_Сервисы.ПометкаУдаления КАК ПометкаУдаления,
	|	кв_Сервисы.Используется КАК Используется,
	|	кв_Сервисы.Ссылка КАК Ссылка
	|ИЗ
	|	Справочник.кв_Сервисы КАК кв_Сервисы
	|ГДЕ
	|	кв_Сервисы.Ссылка <> &Ссылка
	|	И кв_Сервисы.Наименование = &Наименование";
	
	РезультЗапроса = Запрос.Выполнить();
	
	Если НЕ РезультЗапроса.Пустой() Тогда
		
		Шаблон = НСтр("ru = 'Сервис с именем ""%1"" уже существует!'");
		ТекстСообщения = СтрШаблон(Шаблон, Наименование);
		кв_ОбщегоНазначенияКлиентСервер.СообщитьПользователю(ТекстСообщения,, "Наименование", "Объект", Отказ);
		
	КонецЕсли;
		
КонецПроцедуры

#КонецОбласти

#КонецЕсли