version 1.0

workflow annotateRsid_VCFs {

    meta {
    author: "Phuwanat Sakornsakolpat"
        email: "phuwanat.sak@mahidol.edu"
        description: "annotate VCF with rsid from dbsnp"
    }

     input {
        File vcf_file
        File tabix_file
        File dbsnp_vcf_file
        File dbsnp_tbi_file
    }

    call run_annotating { 
            input: vcf = vcf_file, tabix = tabix_file, dbsnp_vcf = dbsnp_vcf_file, dbsnp_tbi = dbsnp_tbi_file
    }

    output {
        File annotated_vcf = run_annotating.out_file
        File annotated_tbi = run_annotating.out_file_tbi
    }

}

task run_annotating {
    input {
        File vcf
        File tabix
        File dbsnp_vcf
        File dbsnp_tbi
        Int memSizeGB = 8
        Int threadCount = 2
        Int diskSizeGB = 3*round(size(vcf, "GB")) + 50
    String out_name = basename(vcf, ".vcf.gz")
    }
    
    command <<<
    mv ~{tabix} ~{vcf}.tbi
    bcftools annotate --set-id '%CHROM\_%POS\_%REF\_%FIRST_ALT' -Oz -o ~{out_name}.id.vcf.gz ~{vcf}
    tabix -p vcf ~{out_name}.id.vcf.gz
    mv ~{dbsnp_tbi} ~{dbsnp_vcf}.tbi
    bcftools annotate -a ~{dbsnp_vcf} -c ID -o ~{out_name}.annotated.vcf.gz ~{out_name}.id.vcf.gz
    tabix -p vcf ~{out_name}.annotated.vcf.gz
    >>>

    output {
        File out_file = select_first(glob("*.annotated.vcf.gz"))
        File out_file_tbi = select_first(glob("*.annotated.vcf.gz.tbi"))
    }

    runtime {
        memory: memSizeGB + " GB"
        cpu: threadCount
        disks: "local-disk " + diskSizeGB + " SSD"
        docker: "quay.io/biocontainers/bcftools@sha256:f3a74a67de12dc22094e299fbb3bcd172eb81cc6d3e25f4b13762e8f9a9e80aa"   # digest: quay.io/biocontainers/bcftools:1.16--hfe4b78e_1
        preemptible: 1
    }

}
