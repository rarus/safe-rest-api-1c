///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022-2025, ООО 1С-Рарус
// Все права защищены. Эта программа и сопроводительные материалы предоставляются
// в соответствии с условиями лицензии Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by-sa/4.0/legalcode
//////////////////////////////////////////////////////////////////////////////////////////////////////

#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

#Область ПрограммныйИнтерфейс

// Регистрирует факт блокировки HTTP-запроса из-за конфликта.
//
// Параметры:
//  Контекст - Структура - Параметры обрабатываемого HTTP-запроса. 
//		См. кв_HttpСервисы.КонтекстЗапроса()
//
Процедура ЗафиксироватьКонфликт(Контекст) Экспорт 
	
	УстановитьПривилегированныйРежим(Истина);
	
	ПустаяСтрока = "";
	КлючИдемпотентности = кв_ОбщегоНазначенияКлиентСервер.СвойствоСтруктуры(Контекст, "КлючИдемпотентности", ПустаяСтрока);
	
	Запрос = Новый Запрос;
	Запрос.УстановитьПараметр("Сервис", Контекст.Сервис);
	Запрос.УстановитьПараметр("Идентификатор", Контекст.Идентификатор);
	Запрос.УстановитьПараметр("КлючИдемпотентности", КлючИдемпотентности);
	Запрос.УстановитьПараметр("ВремяНачала", Контекст.ВремяНачала);
	
	Запрос.Текст = 
	"ВЫБРАТЬ ПЕРВЫЕ 1
	|	кв_ЖурналВходящихHTTPЗапросов.ДатаЗапроса КАК ДатаЗапроса,
	|	кв_ЖурналВходящихHTTPЗапросов.Идентификатор КАК Идентификатор
	|ИЗ
	|	РегистрСведений.кв_ЖурналВходящихHTTPЗапросов КАК кв_ЖурналВходящихHTTPЗапросов
	|ГДЕ
	|	кв_ЖурналВходящихHTTPЗапросов.Сервис = &Сервис
	|	И кв_ЖурналВходящихHTTPЗапросов.Идентификатор <> &Идентификатор
	|	И кв_ЖурналВходящихHTTPЗапросов.КлючИдемпотентности = &КлючИдемпотентности
	|	И (ВЫРАЗИТЬ(кв_ЖурналВходящихHTTPЗапросов.Ответ КАК СТРОКА(1))) = """"
	|	И кв_ЖурналВходящихHTTPЗапросов.КодСостояния = 0
	|	И кв_ЖурналВходящихHTTPЗапросов.ВремяНачала < &ВремяНачала";
	
	РезультатЗапроса = Запрос.Выполнить();
	Если РезультатЗапроса.Пустой() Тогда
		Возврат;
	КонецЕсли;
	
	Выборка = РезультатЗапроса.Выбрать();
	Выборка.Следующий(); 
	
	ИдентификаторЗапроса = Выборка.Идентификатор;
	ДатаБлокировки = Выборка.ДатаЗапроса; 
	
	НаборЗаписей = РегистрыСведений.кв_ЖурналКонфликтовHTTPЗапросов.СоздатьНаборЗаписей();
	НаборЗаписей.Отбор.Сервис.Установить(Контекст.Сервис);
	НаборЗаписей.Отбор.ДатаБлокировки.Установить(ДатаБлокировки);
	НаборЗаписей.Отбор.КлючИдемпотентности.Установить(КлючИдемпотентности);
	
	НаборЗаписей.Прочитать();
	
	Если ЗначениеЗаполнено(НаборЗаписей) Тогда
		
		Для каждого Запись Из НаборЗаписей Цикл
			Запись.ЗаблокированоПовторов = Запись.ЗаблокированоПовторов + 1;
			Запись.ДатаРазблокировки = Дата(1, 1, 1);
		КонецЦикла;
		
	Иначе
		
		Запись = НаборЗаписей.Добавить(); 
		
		Запись.ДатаБлокировки = ДатаБлокировки;
		Запись.КлючИдемпотентности = КлючИдемпотентности;
		Запись.Идентификатор = ИдентификаторЗапроса;
		Запись.Сервис = Контекст.Сервис;
		Запись.Ресурс = Контекст.ОтносительныйURL;
		Запись.ЗаблокированоПовторов = 1;
		
	КонецЕсли;
	
	Попытка
	
		НаборЗаписей.Записать();
	
	Исключение 
		
		ПодробноеПредставлениеОшибки = ПодробноеПредставлениеОшибки(ИнформацияОбОшибке());
		
		Шаблон = НСтр("ru = 'Не удалось зафиксировать конфликт HTTP-запроса, Idempotency-key: %1, ID запроса: %2. %3'");
		ТекстОшибки = СтрШаблон(Шаблон, КлючИдемпотентности, ИдентификаторЗапроса, ПодробноеПредставлениеОшибки);
		
		ИмяСобытия = НСтр("ru = 'Фиксация конфликта по HTTP-запросу'");
		ЗаписьЖурналаРегистрации(ИмяСобытия, УровеньЖурналаРегистрации.Ошибка, , , ТекстОшибки);
	
	КонецПопытки;
	
КонецПроцедуры

// Обработчик регламентного задания кв_РазблокированиеКонфликтныхHTTPЗапросов.
//
Процедура РазблокироватьЗапросы() Экспорт
	
	УстановитьПривилегированныйРежим(Истина);
	
	Запрос = Новый Запрос;
	Запрос.УстановитьПараметр("ПустаяДата", Дата(1, 1, 1));
	Запрос.УстановитьПараметр("ТекущаяДата", ТекущаяДатаСеанса());
	Запрос.УстановитьПараметр("ПустаяСтрока", "");
	
	Запрос.Текст = ТекстЗапросаРазблокировки();
	
	РезультатЗапроса = Запрос.Выполнить();
	
	Выборка = РезультатЗапроса.Выбрать();
	Пока Выборка.Следующий() Цикл
		
		РазблокироватьЗапрос(Выборка, Истина);
		
	КонецЦикла;
		
КонецПроцедуры

// Выполняет разблокирование конфликтного запроса путем удаления из журнала входящих запросов
// 	записи первичного запроса, который не удалось успешно обработать
//
// Параметры:
//  ОписаниеКлюча - Структура - содержит значения ключевых полей записи регистра
//
Процедура РазблокироватьЗапрос(ОписаниеКлюча, Автоматически = Ложь) Экспорт
	
	ДатаРазблокировки = ТекущаяДатаСеанса();
	
	НачатьТранзакцию();
	
	Попытка
		
		РазблокироватьЗаписьЖурналаВходящихЗапросов(ОписаниеКлюча, ДатаРазблокировки, Автоматически);
		
		ЗафиксироватьРазблокировку(ОписаниеКлюча, ДатаРазблокировки);
		
		ЗафиксироватьТранзакцию();
		
	Исключение
		
		ОтменитьТранзакцию();
			 
	КонецПопытки;

КонецПроцедуры

#КонецОбласти

#Область СлужебныйПрограммныйИнтерфейс

// Фиксирует разблокировку запроса в журнале конфликтов.
//
// Параметры:
//  ОписаниеКлюча - Структура - Ключевые параметры записи регистра.
//  ДатаРазблокировки - Дата - Дата разблокирования запроса.
//
Процедура ЗафиксироватьРазблокировку(ОписаниеКлюча, ДатаРазблокировки = Неопределено) Экспорт
	
	Если Не ЗначениеЗаполнено(ДатаРазблокировки) Тогда
		ДатаРазблокировки = ТекущаяДатаСеанса();
	КонецЕсли;
		
	НаборЗаписей = РегистрыСведений.кв_ЖурналКонфликтовHTTPЗапросов.СоздатьНаборЗаписей();
	НаборЗаписей.Отбор.Сервис.Установить(ОписаниеКлюча.Сервис);
	НаборЗаписей.Отбор.ДатаБлокировки.Установить(ОписаниеКлюча.ДатаЗапроса);
	НаборЗаписей.Отбор.КлючИдемпотентности.Установить(ОписаниеКлюча.КлючИдемпотентности);
	
	НаборЗаписей.Прочитать();
	
	Для каждого Запись Из НаборЗаписей Цикл
		Запись.ДатаРазблокировки = ДатаРазблокировки;
	КонецЦикла;
	
	Попытка
		
		НаборЗаписей.Записать();
		
	Исключение
		
		ПодробноеПредставлениеОшибки = ПодробноеПредставлениеОшибки(ИнформацияОбОшибке());
		
		Шаблон = НСтр(
			"ru = 'Не удалось отразить разблокировку конфликта HTTP-запроса, Idempotency-key: %1, ID запроса: %2. %3'");
		
		ТекстОшибки = СтрШаблон(Шаблон, ОписаниеКлюча.КлючИдемпотентности,
			ОписаниеКлюча.Идентификатор, ПодробноеПредставлениеОшибки);
		
		ИмяСобытия = НСтр("ru = 'Отражение разблокировки конфликта по HTTP-запросу'");
		ЗаписьЖурналаРегистрации(ИмяСобытия, УровеньЖурналаРегистрации.Ошибка, , , ТекстОшибки);
		
		ВызватьИсключение;
		
	КонецПопытки; 
	
КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

Процедура РазблокироватьЗаписьЖурналаВходящихЗапросов(ОписаниеКлюча, ДатаРазблокировки, Автоматически)
	
	РежимРазблокировки = ?(Автоматически, "автоматически", "вручную");
	ШаблонМетки = НСтр("ru = '# Запрос разблокирован %1 %2.'");
	МеткаРазблокировки = СтрШаблон(ШаблонМетки, РежимРазблокировки, ДатаРазблокировки);
	
	НаборЗаписей = РегистрыСведений.кв_ЖурналВходящихHTTPЗапросов.СоздатьНаборЗаписей();
	НаборЗаписей.Отбор.ДатаЗапроса.Установить(ОписаниеКлюча.ДатаЗапроса);
	НаборЗаписей.Отбор.Сервис.Установить(ОписаниеКлюча.Сервис);
	НаборЗаписей.Отбор.Идентификатор.Установить(ОписаниеКлюча.Идентификатор);
	
	НаборЗаписей.Прочитать();
	
	Для каждого Запись Из НаборЗаписей Цикл
		Если ЗначениеЗаполнено(Запись.Ответ) Тогда
			Запись.Ответ = СтрШаблон("%1%2%3", Запись.Ответ, Символы.ПС, МеткаРазблокировки);
		Иначе
			Запись.Ответ = МеткаРазблокировки;
		КонецЕсли;
	КонецЦикла;
	
	Попытка
		
		НаборЗаписей.Записать();
		
	Исключение
		
		ПодробноеПредставлениеОшибки = ПодробноеПредставлениеОшибки(ИнформацияОбОшибке());
		
		Шаблон = НСтр("ru = 'Не удалось разблокировать конфликт HTTP-запроса, Idempotency-key: %1, ID запроса: %2. %3'");
		
		ТекстОшибки = СтрШаблон(Шаблон, ОписаниеКлюча.КлючИдемпотентности, 
			ОписаниеКлюча.Идентификатор, ПодробноеПредставлениеОшибки);
		
		ИмяСобытия = НСтр("ru = 'Разблокировка конфликта по HTTP-запросу'");
		ЗаписьЖурналаРегистрации(ИмяСобытия, УровеньЖурналаРегистрации.Ошибка, , , ТекстОшибки);
		
		ВызватьИсключение;
		
	КонецПопытки; 
	
КонецПроцедуры

Функция ТекстЗапросаРазблокировки()
	
	ТекстЗапроса = 
	"ВЫБРАТЬ
	|	Сервисы.Ссылка КАК Сервис,
	|	Сервисы.ПовторовДоРазблокировкиКонфликтов КАК ПовторовДоРазблокировкиКонфликтов,
	|	Сервисы.ПорогРазблокировкиКонфликтов КАК ПорогРазблокировкиКонфликтов,
	|	Сервисы.ПериодПроверкиПорогаРазблокировки КАК ПериодПроверкиПорогаРазблокировки,
	|	Сервисы.ПериодГарантированнойРазблокировки КАК ПериодГарантированнойРазблокировки
	|ПОМЕСТИТЬ ВТ_ПроверяемыеСервисы
	|ИЗ
	|	Справочник.кв_Сервисы КАК Сервисы
	|ГДЕ
	|	Сервисы.Используется
	|	И Сервисы.КонтрольКонфликтовЗапросов
	|	И НЕ Сервисы.ПометкаУдаления
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	ВТ_ПроверяемыеСервисы.Сервис КАК Сервис,
	|	ВТ_ПроверяемыеСервисы.ПовторовДоРазблокировкиКонфликтов КАК ПовторовДоРазблокировкиКонфликтов,
	|	ВТ_ПроверяемыеСервисы.ПериодПроверкиПорогаРазблокировки КАК ПериодПроверкиПорогаРазблокировки,
	|	ВТ_ПроверяемыеСервисы.ПериодГарантированнойРазблокировки КАК ПериодГарантированнойРазблокировки,
	|	СУММА(1) КАК ЗаблокированоПервичныхУникальныхЗапросов,
	|	РАЗНОСТЬДАТ(кв_ЖурналКонфликтовHTTPЗапросов.ДатаБлокировки, &ТекущаяДата, МИНУТА) КАК ПрошлоВремениСМоментаБлокировки
	|ПОМЕСТИТЬ ВТ_ПоказателиСервисов
	|ИЗ
	|	ВТ_ПроверяемыеСервисы КАК ВТ_ПроверяемыеСервисы
	|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ РегистрСведений.кв_ЖурналКонфликтовHTTPЗапросов КАК кв_ЖурналКонфликтовHTTPЗапросов
	|		ПО ВТ_ПроверяемыеСервисы.Сервис = кв_ЖурналКонфликтовHTTPЗапросов.Сервис
	|			И (кв_ЖурналКонфликтовHTTPЗапросов.ДатаРазблокировки = &ПустаяДата)
	|
	|СГРУППИРОВАТЬ ПО
	|	ВТ_ПроверяемыеСервисы.Сервис,
	|	ВТ_ПроверяемыеСервисы.ПорогРазблокировкиКонфликтов,
	|	ВТ_ПроверяемыеСервисы.ПовторовДоРазблокировкиКонфликтов,
	|	РАЗНОСТЬДАТ(кв_ЖурналКонфликтовHTTPЗапросов.ДатаБлокировки, &ТекущаяДата, МИНУТА),
	|	ВТ_ПроверяемыеСервисы.ПериодПроверкиПорогаРазблокировки,
	|	ВТ_ПроверяемыеСервисы.ПериодГарантированнойРазблокировки
	|
	|ИМЕЮЩИЕ
	|	СУММА(1) < ВТ_ПроверяемыеСервисы.ПорогРазблокировкиКонфликтов
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	ВТ_ПоказателиСервисов.Сервис КАК Сервис,
	|	ВТ_ПоказателиСервисов.ПовторовДоРазблокировкиКонфликтов КАК ПовторовДоРазблокировкиКонфликтов,
	|	ВТ_ПоказателиСервисов.ПериодПроверкиПорогаРазблокировки КАК ПериодПроверкиПорогаРазблокировки,
	|	ВТ_ПоказателиСервисов.ЗаблокированоПервичныхУникальныхЗапросов КАК ЗаблокированоПервичныхУникальныхЗапросов,
	|	ВТ_ПоказателиСервисов.ПрошлоВремениСМоментаБлокировки КАК ПрошлоВремениСМоментаБлокировки,
	|	0 КАК ПериодГарантированнойРазблокировки
	|ПОМЕСТИТЬ ВТ_СервисыКРазблокировке
	|ИЗ
	|	ВТ_ПоказателиСервисов КАК ВТ_ПоказателиСервисов
	|ГДЕ
	|	ВТ_ПоказателиСервисов.ПрошлоВремениСМоментаБлокировки МЕЖДУ 0 И ВТ_ПоказателиСервисов.ПериодПроверкиПорогаРазблокировки
	|
	|ОБЪЕДИНИТЬ ВСЕ
	|
	|ВЫБРАТЬ
	|	ВТ_ПоказателиСервисов.Сервис,
	|	ВТ_ПоказателиСервисов.ПовторовДоРазблокировкиКонфликтов,
	|	ВТ_ПоказателиСервисов.ПериодПроверкиПорогаРазблокировки,
	|	ВТ_ПоказателиСервисов.ЗаблокированоПервичныхУникальныхЗапросов,
	|	ВТ_ПоказателиСервисов.ПрошлоВремениСМоментаБлокировки,
	|	ВТ_ПоказателиСервисов.ПериодГарантированнойРазблокировки
	|ИЗ
	|	ВТ_ПоказателиСервисов КАК ВТ_ПоказателиСервисов
	|ГДЕ
	|	ВТ_ПоказателиСервисов.ПериодГарантированнойРазблокировки > 0
	|	И ВТ_ПоказателиСервисов.ПрошлоВремениСМоментаБлокировки >= ВТ_ПоказателиСервисов.ПериодГарантированнойРазблокировки
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	кв_ЖурналКонфликтовHTTPЗапросов.ДатаБлокировки КАК ДатаЗапроса,
	|	кв_ЖурналКонфликтовHTTPЗапросов.КлючИдемпотентности КАК КлючИдемпотентности,
	|	кв_ЖурналКонфликтовHTTPЗапросов.ЗаблокированоПовторов КАК ЗаблокированоПовторов,
	|	кв_ЖурналКонфликтовHTTPЗапросов.Идентификатор КАК Идентификатор,
	|	кв_ЖурналКонфликтовHTTPЗапросов.Сервис КАК Сервис,
	|	кв_ЖурналКонфликтовHTTPЗапросов.ДатаРазблокировки КАК ДатаРазблокировки
	|ИЗ
	|	ВТ_СервисыКРазблокировке КАК ВТ_СервисыКРазблокировке
	|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ РегистрСведений.кв_ЖурналКонфликтовHTTPЗапросов КАК кв_ЖурналКонфликтовHTTPЗапросов
	|			ВНУТРЕННЕЕ СОЕДИНЕНИЕ РегистрСведений.кв_ЖурналВходящихHTTPЗапросов КАК кв_ЖурналВходящихHTTPЗапросов
	|			ПО кв_ЖурналКонфликтовHTTPЗапросов.ДатаБлокировки = кв_ЖурналВходящихHTTPЗапросов.ДатаЗапроса
	|				И кв_ЖурналКонфликтовHTTPЗапросов.Сервис = кв_ЖурналВходящихHTTPЗапросов.Сервис
	|				И кв_ЖурналКонфликтовHTTPЗапросов.Идентификатор = кв_ЖурналВходящихHTTPЗапросов.Идентификатор
	|				И кв_ЖурналКонфликтовHTTPЗапросов.КлючИдемпотентности = кв_ЖурналВходящихHTTPЗапросов.КлючИдемпотентности
	|				И (кв_ЖурналВходящихHTTPЗапросов.КодСостояния = 0)
	|		ПО ВТ_СервисыКРазблокировке.Сервис = кв_ЖурналКонфликтовHTTPЗапросов.Сервис
	|			И (кв_ЖурналКонфликтовHTTPЗапросов.ЗаблокированоПовторов >= ВТ_СервисыКРазблокировке.ПовторовДоРазблокировкиКонфликтов)
	|			И (кв_ЖурналКонфликтовHTTPЗапросов.ДатаРазблокировки = &ПустаяДата)
	|ГДЕ
	|	(ВЫРАЗИТЬ(кв_ЖурналВходящихHTTPЗапросов.Ответ КАК СТРОКА(1))) = """"";
	
	Возврат ТекстЗапроса;
	
КонецФункции

#КонецОбласти

#КонецЕсли