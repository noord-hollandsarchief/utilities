<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
				xmlns:x="http://www.nationaalarchief.nl/ToPX/v2.3" 
				xmlns="http://www.nationaalarchief.nl/ToPX/v2.3" 
				exclude-result-prefixes="x">
	<xsl:output method="xml"
	            version="1.0"
	            encoding="UTF-8"
	            indent="yes"/>
	<xsl:strip-space elements="*"/>
	
	<xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
	
	<xsl:param name="recordName" select="document('record.xml')/x:ToPX/x:aggregatie/x:naam/text()" />
	<xsl:param name="pReplacement" select="concat('Titel: ', $recordName, ' (Bestandsnaam: ', /x:ToPX/x:bestand/x:naam/text(), ')')"/>
	
	<xsl:template match="/x:ToPX/x:bestand/x:naam/text()">
		<xsl:value-of select="$pReplacement"/>
   </xsl:template>
</xsl:stylesheet>
