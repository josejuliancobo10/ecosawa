Add-Type -AssemblyName System.IO.Compression.FileSystem

# Leer plantilla de header y footer desde code_6.html
$template = [System.IO.File]::ReadAllText("c:\Users\Usuario\Desktop\Websites\Ecosawa diseno\code_6.html", [System.Text.Encoding]::UTF8)
$headerParts = $template -split '<!-- SCROLL ANIMATIONS -->'
$headerHtml = $headerParts[0] -replace '<main.*?</main>', ''
$footerHtml = '<!-- SCROLL ANIMATIONS -->' + $headerParts[1]

# Asegurar que el headerHTML termine antes del footer
$headerOnly = $headerHtml.Substring(0, $headerHtml.IndexOf('<footer'))
$footerOnly = $template.Substring($template.IndexOf('<footer'))

function Process-Docx($path) {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($path)
    $doc = $zip.GetEntry("word/document.xml")
    $paragraphs = @()
    if ($doc) {
        $stream = $doc.Open()
        $reader = New-Object System.IO.StreamReader($stream)
        $xmlContent = $reader.ReadToEnd()
        $reader.Close()
        $stream.Close()
        
        $xml = [xml]$xmlContent
        $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
        $ns.AddNamespace("w", "http://schemas.openxmlformats.org/wordprocessingml/2006/main")
        
        $nodes = $xml.SelectNodes("//w:p", $ns)
        foreach ($p in $nodes) {
            $texts = $p.SelectNodes(".//w:t", $ns)
            $text = ($texts | ForEach-Object { $_.InnerText }) -join ""
            if ($text.Trim() -ne "") {
                $paragraphs += $text.Trim()
            }
        }
    }
    $zip.Dispose()
    return $paragraphs
}

$files = Get-ChildItem "c:\Users\Usuario\Desktop\Websites\Ecosawa diseno\*.docx" | Where-Object { $_.Name -match '^\d{2}-' }

$links = @()

foreach ($file in $files) {
    Write-Host "Procesando $($file.Name)..."
    $lines = Process-Docx $file.FullName
    
    $title = $lines[0]
    $category = $lines[1] -replace 'Categor[íi]a:\s*', ''
    $metaTitle = $lines[2] -replace 'Meta t[íi]tulo SEO:\s*', ''
    $metaDesc = $lines[3] -replace 'Meta descripci[óo]n SEO:\s*', ''
    $keywords = $lines[4] -replace 'Palabras clave objetivo:\s*', ''
    
    $slug = $file.Name.Replace(".docx", ".html")
    $links += @{ url=$slug; title=$title; cat=$category }

    $bodyHtml = "<main class='w-full pt-32 pb-20'><article class='max-w-[800px] mx-auto px-6'>"
    
    # Meta SEO Injection in Header
    $customHeader = $headerOnly -replace '<title>.*?</title>', "<title>$metaTitle</title>`n<meta name='description' content='$metaDesc'>`n<meta name='keywords' content='$keywords'>"
    
    $bodyHtml += "<div class='mb-8'><span class='text-sm font-bold text-primary uppercase tracking-wider'>$category</span>"
    $bodyHtml += "<h1 class='text-4xl md:text-5xl font-bold text-slate-800 mt-2 mb-6'>$title</h1></div>"
    
    $bodyHtml += "<div class='prose prose-lg prose-green max-w-none text-slate-600'>"
    for ($i = 5; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        if ($line.Length -lt 80 -and $line -notmatch '\.') {
            $bodyHtml += "<h2 class='text-2xl font-bold text-primary mt-8 mb-4'>$line</h2>"
        } else {
            $bodyHtml += "<p class='mb-4 leading-relaxed'>$line</p>"
        }
    }
    $bodyHtml += "</div></article></main>"
    
    $fullHtml = $customHeader + $bodyHtml + $footerOnly
    [System.IO.File]::WriteAllText("c:\Users\Usuario\Desktop\Websites\Ecosawa diseno\$slug", $fullHtml, [System.Text.Encoding]::UTF8)
}

Write-Host "Generados $($links.Count) archivos HTML."